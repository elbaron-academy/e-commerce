import '../../../core/network/api_client.dart';
import '../domain/address.dart';

class AddressRepositoryImpl implements AddressRepository {
  AddressRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<List<Address>> list() async {
    final data = await _api.get<List<dynamic>>('/addresses/');
    return [for (final a in data) Address.fromJson(a as Map<String, dynamic>)];
  }

  @override
  Future<Address> create(AddressInput input) async =>
      Address.fromJson(await _api.post<Map<String, dynamic>>('/addresses/', data: input.toJson()));

  @override
  Future<void> setDefault(int id) => _api.patch<dynamic>('/addresses/$id/', data: {'is_default': true});

  @override
  Future<void> delete(int id) => _api.delete('/addresses/$id/');
}
