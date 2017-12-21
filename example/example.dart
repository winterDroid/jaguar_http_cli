library jaguar_http.example;

import 'dart:async';
import 'package:http/http.dart';
import 'package:jaguar_http/jaguar_http.dart';
import 'package:jaguar_serializer/jaguar_serializer.dart';
import 'models/user.dart';

part 'example.g.dart';

/// definition
@JaguarHttp(name: "Api")
abstract class ApiDefinition {
  @Get("/users/:id")
  Future<JaguarResponse<User>> getUserById(@Param() String id);

  @Post("/users")
  Future<JaguarResponse<User>> postUser(@Body() User user);

  @Put("/users/:uid")
  Future<JaguarResponse<User>> updateUser(
      @Param("uid") String userId, @Body() User user);

  @Delete("/users/:id")
  Future<JaguarResponse> deleteUser(@Param() String id);

  @Get("/users")
  Future<JaguarResponse<List<User>>> search(
      {@QueryParam("n") String name, @QueryParam("e") String email});
}

JsonRepo repo = new JsonRepo()..add(new UserSerializer());

void main() {
  ApiDefinition api = new Api(
      client: new IOClient(),
      baseUrl: "http://localhost:9000",
      serializers: repo)
    ..requestInterceptors.add((JaguarRequest req) {
      req.headers["Authorization"] = "TOKEN";
      return req;
    });

  api.getUserById("userId").then((JaguarResponse res) {
    print(res);
  }, onError: (e) {
    print(e);
  });
}
