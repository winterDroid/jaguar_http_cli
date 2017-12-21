import 'dart:async';
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:jaguar_http/src/core/definitions.dart';
import 'package:jaguar_http_cli/src/generator/utils.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/annotation.dart';
import 'package:source_gen/src/utils.dart';
import 'package:code_builder/code_builder.dart';

class JaguarHttpGenerator extends GeneratorForAnnotation<JaguarHttp> {
  const JaguarHttpGenerator();

  Future<String> generateForAnnotatedElement(
      Element element, JaguarHttp annotation, BuildStep buildStep) async {
    if (element is! ClassElement) {
      var friendlyName = friendlyNameForElement(element);
      throw new InvalidGenerationSourceError(
          'Generator cannot target `$friendlyName`.',
          todo: 'Remove the JaguarHttp annotation from `$friendlyName`.');
    }

    return _buildImplementionClass(annotation, element);
  }

  String _buildImplementionClass(JaguarHttp annotation, ClassElement element) {
    var friendlyName = element.name;

    ReferenceBuilder base = reference(friendlyName);
    ReferenceBuilder core = reference("$JaguarApiDefinition");
    ClassBuilder clazz = new ClassBuilder(
        annotation.name ?? "${friendlyName}Impl",
        asWith: [base],
        asExtends: core);

    _buildConstructor(clazz);

    element.methods.forEach((MethodElement m) {
      ElementAnnotation methodAnnot = _getMethodAnnotation(m);
      if (methodAnnot != null &&
          m.isAbstract &&
          m.returnType.isDartAsyncFuture) {
        TypeBuilder returnType = _genericTypeBuilder(m.returnType);

        MethodBuilder methodBuilder = new MethodBuilder(m.name,
            returnType: returnType, modifier: MethodModifier.asAsync);

        final statements = [
          _generateUrl(m, methodAnnot),
          _generateRequest(m, methodAnnot),
          _generateInterceptRequest(),
          _generateSendRequest(),
          varField(kResponse),
          _generateResponseProcess(m),
          _generateInterceptResponse(),
          kResponseRef.asReturn()
        ];

        methodBuilder.addStatements(statements);

        m.parameters.forEach((ParameterElement param) {
          if (param.parameterKind == ParameterKind.NAMED) {
            methodBuilder.addNamed(new ParameterBuilder(param.name,
                type: new TypeBuilder(param.type.name)));
          } else {
            methodBuilder.addPositional(new ParameterBuilder(param.name,
                type: new TypeBuilder(param.type.name)));
          }
        });

        clazz.addMethod(methodBuilder);
      }
    });

    return clazz.buildClass().toString();
  }

  _buildConstructor(ClassBuilder clazz) {
    clazz.addConstructor(new ConstructorBuilder(
        invokeSuper: [kClientRef, kBaseUrlRef, kHeadersRef, kSerializersRef])
      ..addNamed(new ParameterBuilder(kClient, type: kHttpClientType))
      ..addNamed(new ParameterBuilder(kBaseUrl, type: kStringType))
      ..addNamed(new ParameterBuilder(kHeaders, type: kMapType))
      ..addNamed(new ParameterBuilder(kSerializers, type: kSerializerType)));
  }

  ElementAnnotation _getMethodAnnotation(MethodElement method) =>
      method.metadata.firstWhere((ElementAnnotation annot) {
        return _methodsAnnotations.any((type) => matchAnnotation(type, annot));
      }, orElse: () => null);

  ElementAnnotation _getParamAnnotation(ParameterElement param) =>
      param.metadata.firstWhere((ElementAnnotation annot) {
        return matchAnnotation(Param, annot);
      }, orElse: () => null);

  ElementAnnotation _getQueryParamAnnotation(ParameterElement param) =>
      param.metadata.firstWhere((ElementAnnotation annot) {
        return matchAnnotation(QueryParam, annot);
      }, orElse: () => null);

  ElementAnnotation _getBodyAnnotation(ParameterElement param) =>
      param.metadata.firstWhere((ElementAnnotation annot) {
        return matchAnnotation(Body, annot);
      }, orElse: () => null);

  final _methodsAnnotations = const [Get, Post, Delete, Put, Patch];

  DartType _genericOf(DartType type) {
    return type is InterfaceType && type.typeArguments.isNotEmpty
        ? type.typeArguments.first
        : null;
  }

  TypeBuilder _genericTypeBuilder(DartType type) {
    final generic = _genericOf(type);
    if (generic == null) {
      return new TypeBuilder(type.name);
    }
    return new TypeBuilder(type.name, genericTypes: [
      _genericTypeBuilder(generic),
    ]);
  }

  DartType _getResponseType(DartType type) {
    final generic = _genericOf(type);
    if (generic == null) {
      return type;
    }
    if (generic.isDynamic) {
      return null;
    }
    return _getResponseType(generic);
  }

  StatementBuilder _generateUrl(
      MethodElement method, ElementAnnotation methodAnnot) {
    final annot = instantiateAnnotation(methodAnnot) as Req;

    String value = "${annot.url}";
    Map query = <String, String>{};
    method.parameters?.forEach((ParameterElement p) {
      if (p.parameterKind == ParameterKind.POSITIONAL) {
        var pAnnot = _getParamAnnotation(p);
        pAnnot = pAnnot != null ? instantiateAnnotation(pAnnot) : null;
        if (pAnnot != null) {
          String key = ":${(pAnnot as Param).name ?? p.name}";
          value = value.replaceFirst(key, "\${${p.name}}");
        }
      } else if (p.parameterKind == ParameterKind.NAMED) {
        var pAnnot = _getQueryParamAnnotation(p);
        pAnnot = pAnnot != null ? instantiateAnnotation(pAnnot) : null;
        if (pAnnot != null) {
          query[(pAnnot as QueryParam).name ?? p.name] = p.name;
        }
      }
    });

    if (query.isNotEmpty) {
      String q = "{";
      query.forEach((key, val) {
        q += '"$key": "\$$val",';
      });
      q += "}";

      return literal('\$$kBaseUrl$value?\${$kParamsToQueryUri($q)}')
          .asFinal(kUrl);
    }

    return literal('\$$kBaseUrl$value').asFinal(kUrl);
  }

  StatementBuilder _generateRequest(
      MethodElement method, ElementAnnotation methodAnnot) {
    final annot = instantiateAnnotation(methodAnnot) as Req;

    final params = {
      kMethod: new ExpressionBuilder.raw((_) => "'${annot.method}'"),
      kUrl: kUrlRef,
      kHeaders: kHeadersRef
    };

    method.parameters?.forEach((ParameterElement p) {
      var pAnnot = _getBodyAnnotation(p);
      pAnnot = pAnnot != null ? instantiateAnnotation(pAnnot) : null;
      if (pAnnot != null) {
        params[kBody] =
            kSerializersRef.invoke(kSerializeMethod, [reference(p.name)]);
      }
    });

    return kJaguarRequestRef.newInstance([], named: params).asVar(kRequest);
  }

  StatementBuilder _generateInterceptRequest() =>
      kInterceptReqRef.call([kRequestRef]).asAssign(kRequestRef);

  StatementBuilder _generateInterceptResponse() =>
      kInterceptResRef.call([kResponseRef]).asAssign(kResponseRef);

  StatementBuilder _generateSendRequest() => varFinal(kRawResponse,
      value: kRequestRef.invoke(kSendMethod, [kClientRef]).asAwait());

  StatementBuilder _generateResponseProcess(MethodElement method) {
    final named = {};

    final responseType = _getResponseType(method.returnType);

    if (responseType != null) {
      named[kType] = new ExpressionBuilder.raw((_) => "${responseType.name}");
    }

    return ifThen(kResponseSuccessfulRef.call([kRawResponseRef]))
      ..addStatement(kJaguarResponseRef.newInstance([
        kSerializersRef.invoke(kDeserializeMethod, [kRawResponseBodyRef],
            namedArguments: named),
        kRawResponseRef
      ]).asAssign(kResponseRef))
      ..setElse(kJaguarResponseRef.newInstance([kRawResponseRef],
          constructor: kError).asAssign(kResponseRef));
  }
}
