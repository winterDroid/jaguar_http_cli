// GENERATED CODE - DO NOT MODIFY BY HAND

part of example.user;

// **************************************************************************
// Generator: SerializerGenerator
// Target: class UserSerializer
// **************************************************************************

abstract class _$UserSerializer implements Serializer<User> {
  Map toMap(User model, {bool withType: false, String typeKey}) {
    Map ret = new Map();
    if (model != null) {
      if (model.name != null) {
        ret["name"] = model.name;
      }
      if (model.email != null) {
        ret["email"] = model.email;
      }
      if (modelString() != null && withType) {
        ret[typeKey ?? defaultTypeInfoKey] = modelString();
      }
    }
    return ret;
  }

  User fromMap(Map map, {User model, String typeKey}) {
    if (map is! Map) {
      return null;
    }
    if (model is! User) {
      model = createModel();
    }
    model.name = map["name"];
    model.email = map["email"];
    return model;
  }

  String modelString() => "User";
}
