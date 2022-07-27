Account acc = new Account(Name='test');
fflib_SObjectUnitOfWorkPartial uow = new fflib_SObjectUnitOfWorkPartial(new List<Schema.SObjectType>{Account.SObjectType});
uow.registerNew(acc);
Map<String,Map<String,Object>> results = uow.commitWork(false);
System.debug(JSON.serializePretty(results));