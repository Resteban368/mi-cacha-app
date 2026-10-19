import '../../../../core/usecase/usecase.dart';
import '../entities/push_permission.dart';
import '../entities/push_snapshot.dart';
import '../repositories/push_repository.dart';

class GetPushStatus implements UseCase<PushSnapshot, NoParams> {
  const GetPushStatus(this._repository);

  final PushRepository _repository;

  @override
  Future<PushSnapshot> call(NoParams params) => _repository.status();
}

class EnablePush implements UseCase<PushPermission, NoParams> {
  const EnablePush(this._repository);

  final PushRepository _repository;

  @override
  Future<PushPermission> call(NoParams params) => _repository.enable();
}

class DisablePush implements UseCase<void, NoParams> {
  const DisablePush(this._repository);

  final PushRepository _repository;

  @override
  Future<void> call(NoParams params) => _repository.disable();
}
