public interface fflib_IUnitOfWorkPartialFactory extends fflib_IUnitOfWorkFactory{
	fflib_ISObjectUnitOfWorkPartial newInstance(Boolean allOrNone);
	fflib_ISObjectUnitOfWorkPartial newInstance(fflib_SObjectUnitOfWorkPartial.IDMLP dml);
	fflib_ISObjectUnitOfWorkPartial newInstance(fflib_SObjectUnitOfWorkPartial.IResponse resp);
	fflib_ISObjectUnitOfWorkPartial newInstance(List<SObjectType> objectTypes, Boolean allOrNone);
	fflib_ISObjectUnitOfWorkPartial newInstance(List<SObjectType> objectTypes, fflib_SObjectUnitOfWorkPartial.IResponse resp);
	fflib_ISObjectUnitOfWorkPartial newInstance(List<SObjectType> objectTypes, fflib_SObjectUnitOfWorkPartial.IDMLP dml);
	fflib_ISObjectUnitOfWorkPartial newInstance(List<SObjectType> objectTypes, fflib_SObjectUnitOfWorkPartial.IDMLP dml, fflib_SObjectUnitOfWorkPartial.IResponse resp);
}
