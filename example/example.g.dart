// GENERATED CODE - DO NOT MODIFY BY HAND

part of jaguar_http.example;

// **************************************************************************
// Generator: JaguarHttpGenerator
// Target: abstract class ApiDefinition
// **************************************************************************

class Api extends JaguarApiDefinition with ApiDefinition {
  Api({Client client, String baseUrl, Map headers, SerializerRepo serializers})
      : super(client, baseUrl, headers, serializers);
  Future<JaguarResponse<User>> getUserById(String id) async {
    final url = '$baseUrl/users/:id';
    var request = new JaguarRequest(method: 'GET', url: url, headers: headers);
    request = interceptRequest(request);
    final rawResponse = await request.send(client);
    var response;
    if (responseSuccessful(rawResponse)) {
      response = new JaguarResponse(
          serializers.deserialize(rawResponse.body, type: User), rawResponse);
    } else
      response = new JaguarResponse.error(rawResponse);
    response = interceptResponse(response);
    return response;
  }

  Future<JaguarResponse<User>> postUser(User user) async {
    final url = '$baseUrl/users';
    var request = new JaguarRequest(
        method: 'POST',
        url: url,
        headers: headers,
        body: serializers.serialize(user));
    request = interceptRequest(request);
    final rawResponse = await request.send(client);
    var response;
    if (responseSuccessful(rawResponse)) {
      response = new JaguarResponse(
          serializers.deserialize(rawResponse.body, type: User), rawResponse);
    } else
      response = new JaguarResponse.error(rawResponse);
    response = interceptResponse(response);
    return response;
  }

  Future<JaguarResponse<User>> updateUser(String userId, User user) async {
    final url = '$baseUrl/users/:uid';
    var request = new JaguarRequest(
        method: 'PUT',
        url: url,
        headers: headers,
        body: serializers.serialize(user));
    request = interceptRequest(request);
    final rawResponse = await request.send(client);
    var response;
    if (responseSuccessful(rawResponse)) {
      response = new JaguarResponse(
          serializers.deserialize(rawResponse.body, type: User), rawResponse);
    } else
      response = new JaguarResponse.error(rawResponse);
    response = interceptResponse(response);
    return response;
  }

  Future<JaguarResponse<dynamic>> deleteUser(String id) async {
    final url = '$baseUrl/users/:id';
    var request =
        new JaguarRequest(method: 'DELETE', url: url, headers: headers);
    request = interceptRequest(request);
    final rawResponse = await request.send(client);
    var response;
    if (responseSuccessful(rawResponse)) {
      response = new JaguarResponse(
          serializers.deserialize(rawResponse.body), rawResponse);
    } else
      response = new JaguarResponse.error(rawResponse);
    response = interceptResponse(response);
    return response;
  }

  Future<JaguarResponse<List<User>>> search({String name, String email}) async {
    final url =
        '$baseUrl/users?${paramsToQueryUri({"n": "$name","e": "$email",})}';
    var request = new JaguarRequest(method: 'GET', url: url, headers: headers);
    request = interceptRequest(request);
    final rawResponse = await request.send(client);
    var response;
    if (responseSuccessful(rawResponse)) {
      response = new JaguarResponse(
          serializers.deserialize(rawResponse.body, type: User), rawResponse);
    } else
      response = new JaguarResponse.error(rawResponse);
    response = interceptResponse(response);
    return response;
  }
}
