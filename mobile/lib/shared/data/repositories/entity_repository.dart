import '../../domain/life_entity.dart';

abstract interface class EntityRepository {
  Future<List<LifeEntity>> all();

  Future<LifeEntity?> byId(String id);

  Future<LifeEntity> create(LifeEntity entity);

  Future<LifeEntity> update(LifeEntity entity);

  Future<void> delete(String id);
}
