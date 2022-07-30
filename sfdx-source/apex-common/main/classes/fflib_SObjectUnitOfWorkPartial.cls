public virtual class fflib_SObjectUnitOfWorkPartial 
    extends fflib_SObjectUnitOfWork 
    implements fflib_ISObjectUnitOfWorkPartial {    
        public Map<String, Type> m_eventTypeMap = new Map<String, Type>{
            'publishBeforeEventsStarting' => List<Database.SaveResult>.class
            ,'insertDmlByType' => List<Database.SaveResult>.class
            ,'updateDmlByType' => List<Database.SaveResult>.class
            ,'deleteDmlByType' => List<Database.DeleteResult>.class
            ,'emptyRecycleBinByType' => List<Database.EmptyRecycleBinResult>.class
            ,'publishAfterEvents' => List<Database.SaveResult>.class
        };
        protected Map<String, List<SObject>> m_publishAfterListByType = new Map<String, List<SObject>>();
        protected List<IDoWorkPartial> m_workListPartial = new List<IDoWorkPartial>();
        @TestVisible protected IEmailWorkPartial m_emailWorkPartial = new SendEmailWorkPartial();
        protected IDMLP m_dmlp;    
        /**
         * Interface describes work to be performed during the commitWork method
         **/
        public interface IDoWorkPartial
        {
            void doWork(Map<String,Map<String,Object>> resultMap);
        }
        
        public interface IDMLP
        {
            List<Database.SaveResult> dmlInsert(List<SObject> objList);
            List<Database.SaveResult> dmlUpdate(List<SObject> objList);
            List<Database.DeleteResult> dmlDelete(List<SObject> objList);
            List<Database.SaveResult> eventPublish(List<SObject> objList);
            List<Database.EmptyRecycleBinResult> emptyRecycleBin(List<SObject> objList);
        }
    
        public virtual class SimpleDMLPartial implements IDMLP
        {
            public virtual List<Database.SaveResult> dmlInsert(List<SObject> objList)
            {
                return Database.insert(objList,false);
            }
            public virtual List<Database.SaveResult> dmlUpdate(List<SObject> objList)
            {
                return Database.update(objList,false);
            }
            public virtual List<Database.DeleteResult> dmlDelete(List<SObject> objList)
            {
                return Database.delete(objList,false);
            }
            public virtual List<Database.SaveResult> eventPublish(List<SObject> objList)
            {
                return EventBus.publish(objList);
            }
            public virtual List<Database.EmptyRecycleBinResult> emptyRecycleBin(List<SObject> objList)
            {
                if (objList.isEmpty())
                {
                    return null;
                }    
                return Database.emptyRecycleBin(objList);
            }
        }

        /**
         * Internal implementation of Messaging.sendEmail, see outer class registerEmail method
         **/
        public interface IEmailWorkPartial extends IDoWorkPartial
        {
            void registerEmail(Messaging.Email email);
        }
    
        private class SendEmailWorkPartial implements IEmailWorkPartial
        {
            private List<Messaging.Email> emails;
    
            public SendEmailWorkPartial()
            {
                this.emails = new List<Messaging.Email>();
            }
    
            public void registerEmail(Messaging.Email email)
            {
                this.emails.add(email);
            }
    
            public void doWork(Map<String,Map<String,Object>> resultMap)
            {
                if (emails.size() > 0){
                    resultMap.put('SendEmailWork',new Map<String,Object>());
                    resultMap.get('SendEmailWork').put('Email',Messaging.sendEmail(emails,false));
                }
            }
        }
    /**
     * Constructs a new UnitOfWork to support work against the given object list
     *
     * @param sObjectTypes A list of objects given in dependency order (least dependent first)
     */
    public fflib_SObjectUnitOfWorkPartial(List<Schema.SObjectType> sObjectTypes)
    {
      this(sObjectTypes,new SimpleDMLPartial());
    }
    public fflib_SObjectUnitOfWorkPartial(List<Schema.SObjectType> sObjectTypes, IDMLP dml)
    {
        super(sObjectTypes);
        m_dmlp = dml;
        for (Schema.SObjectType sObjectType : m_sObjectTypes)
        {
            // register the type
            handleRegisterTypePartial(sObjectType);
        }
    }
    public fflib_SObjectUnitOfWorkPartial(List<Schema.SObjectType> sObjectTypes, fflib_SObjectUnitOfWork.IDML dml)
    {
        super(sObjectTypes,dml);
    }
    /***
     * virtuals
     */
    public virtual void onRegisterTypePartial(Schema.SObjectType sObjectType) {
        onRegisterType(sObjectType);
    }
    public virtual void onCommitWorkStartingPartial(Map<String,Map<String,Object>> resultMap) {
        onCommitWorkStarting();
    }
    public virtual void onPublishBeforeEventsStartingPartial(Map<String,Map<String,Object>> resultMap) {
        onPublishBeforeEventsStarting();
    }
    public virtual void onPublishBeforeEventsFinishedPartial(Map<String,Map<String,Object>> resultMap) {
        onPublishBeforeEventsFinished();
    }
    public virtual void onDMLStartingPartial(Map<String,Map<String,Object>> resultMap) {
        onDMLStarting();
    }
    public virtual void onDMLFinishedPartial(Map<String,Map<String,Object>> resultMap) {
        onDMLFinished();
    }
    public virtual void onDoWorkStartingPartial(Map<String,Map<String,Object>> resultMap) {
        onDoWorkStarting();
    }
    public virtual void onDoWorkFinishedPartial(Map<String,Map<String,Object>> resultMap) {
        onDoWorkFinished();
    }
    public virtual void onPublishAfterEventsStartingPartial(Map<String,Map<String,Object>> resultMap) {
        onPublishAfterSuccessEventsStarting();
    }
    public virtual void onPublishAfterEventsFinishedPartial(Map<String,Map<String,Object>> resultMap) {
        onPublishAfterSuccessEventsFinished();
    }
    public virtual void onCommitWorkFinishingPartial(Map<String,Map<String,Object>> resultMap) {
        onCommitWorkFinishing();
    }
    public virtual void onCommitWorkFinishedPartial(Map<String,Map<String,Object>> resultMap) {}

    /**
     * Registers the type to be used for DML operations
     *
     * @param sObjectType - The type to register
     *
     */
    private void handleRegisterTypePartial(Schema.SObjectType sObjectType)
    {
        String sObjectName = sObjectType.getDescribe().getName();

        // add type to dml operation tracking
        m_publishAfterListByType.put(sObjectName, new List<SObject>());

        // give derived class opportunity to register the type
        onRegisterTypePartial(sObjectType);
    }
    /**
     * Register a newly created SObject (Platform Event) instance to be published when commitWork is called
     *
     * @param record A newly created SObject (Platform Event) instance to be inserted during commitWork
     **/
    public void registerPublishAfterTransaction(SObject record)
    {
        String sObjectType = record.getSObjectType().getDescribe().getName();

		assertForEventSObjectType(sObjectType);
		assertForSupportedSObjectType(m_publishAfterListByType, sObjectType);

        m_publishAfterListByType.get(sObjectType).add(record);
    }
    /**
     * Register a list of newly created SObject (Platform Event) instance to be published when commitWork is called
     *
     * @param records A list of existing records
     **/
    public void registerPublishAfterTransaction(List<SObject> records)
    {
        for (SObject record : records)
        {
            this.registerPublishAfterSuccessTransaction(record);
        }
    }
    /**
     * Register a generic piece of work to be invoked during the commitWork phase
     **/
    public void registerWork(IDoWorkPartial work)
    {
        m_workListPartial.add(work);
    }
    /**
     * Takes all the work that has been registered with the UnitOfWork and commits it to the database with allOrNone set a passed
     **/
    public Map<String,Map<String,Object>> commitWork(Boolean allOrNone){
        if(allOrNone){
            this.commitWork();
            return null;
        }else{
            //map = Unit of Work Event -> SObject Type Name -> Object containing Database Result Lists
            Map<String,Map<String,Object>> returnMap = new Map<String,Map<String,Object>>();
            doCommitWork(returnMap);
            doAfterCommitWorkStepsPartial(returnMap);
            return returnMap;
        }
    }

	private void doCommitWork(Map<String,Map<String,Object>> resultMap)
	{
		onCommitWorkStartingPartial(resultMap);
		onPublishBeforeEventsStartingPartial(resultMap);
		publishBeforeEventsStartingPartial(resultMap);
		onPublishBeforeEventsFinishedPartial(resultMap);

		onDMLStartingPartial(resultMap);
		insertDmlByTypePartial(resultMap);
		updateDmlByTypePartial(resultMap);
		deleteDmlByTypePartial(resultMap);
		emptyRecycleBinByTypePartial(resultMap);
		resolveEmailRelationships();
		onDMLFinishedPartial(resultMap);

		onDoWorkStartingPartial(resultMap);
		doWorkPartial(resultMap);
		onDoWorkFinishedPartial(resultMap);
		onCommitWorkFinishingPartial(resultMap);
	}

	private void doAfterCommitWorkStepsPartial(Map<String,Map<String,Object>> resultMap)
	{
		doAfterCommitWorkAfterStepsPartial(resultMap);
        onCommitWorkFinishedPartial(resultMap);
	}

	private void doAfterCommitWorkAfterStepsPartial(Map<String,Map<String,Object>> resultMap)
	{
		onPublishAfterEventsStartingPartial(resultMap);
		publishAfterEventsPartial(resultMap);
		onPublishAfterEventsFinishedPartial(resultMap);
	}

	private void publishBeforeEventsStartingPartial(Map<String,Map<String,Object>> resultMap)
	{
		resultMap.put('publishBeforeEventsStarting',new Map<String,Object>());
    for (Schema.SObjectType sObjectType : m_sObjectTypes)
		{
			resultMap.get('publishBeforeEventsStarting').put(
                sObjectType.getDescribe().getName()
                ,m_dmlp.eventPublish(m_publishBeforeListByType.get(sObjectType.getDescribe().getName()))
            );
		}
	}

	private void insertDmlByTypePartial(Map<String,Map<String,Object>> resultMap)
	{
		resultMap.put('insertDmlByType',new Map<String,Object>());
		for (Schema.SObjectType sObjectType : m_sObjectTypes)
		{
			m_relationships.get(sObjectType.getDescribe().getName()).resolve();
            resultMap.get('insertDmlByType').put(
                sObjectType.getDescribe().getName()
                ,m_dmlp.dmlInsert(m_newListByType.get(sObjectType.getDescribe().getName()))
            );
		}
	}

	private void updateDmlByTypePartial(Map<String,Map<String,Object>> resultMap)
	{
		resultMap.put('updateDmlByType',new Map<String,Object>());
		for (Schema.SObjectType sObjectType : m_sObjectTypes)
		{
            resultMap.get('updateDmlByType').put(
                sObjectType.getDescribe().getName()
                ,m_dmlp.dmlUpdate(m_dirtyMapByType.get(sObjectType.getDescribe().getName()).values())
            );
		}
	}

	private void deleteDmlByTypePartial(Map<String,Map<String,Object>> resultMap)
	{
		resultMap.put('deleteDmlByType',new Map<String,Object>());
		Integer objectIdx = m_sObjectTypes.size() - 1;
		while (objectIdx >= 0)
		{
            resultMap.get('deleteDmlByType').put(
                m_sObjectTypes[objectIdx].getDescribe().getName()
                ,m_dmlp.dmlDelete(m_deletedMapByType.get(m_sObjectTypes[objectIdx--].getDescribe().getName()).values())
            );
		}
	}

	private void emptyRecycleBinByTypePartial(Map<String,Map<String,Object>> resultMap)
	{
		resultMap.put('emptyRecycleBinByType',new Map<String,Object>());
		Integer objectIdx = m_sObjectTypes.size() - 1;
		while (objectIdx >= 0)
		{
            resultMap.get('emptyRecycleBinByType').put(
                m_sObjectTypes[objectIdx].getDescribe().getName()
                ,m_dmlp.emptyRecycleBin(m_emptyRecycleBinMapByType.get(m_sObjectTypes[objectIdx--].getDescribe().getName()).values())
            );
		}
	}

	private void doWorkPartial(Map<String,Map<String,Object>> resultMap)
	{
		m_workListPartial.add(m_emailWorkPartial);
		for (IDoWorkPartial work : m_workListPartial)
		{
      try{
        work.doWork(resultMap);
      }catch(Exception e){
        if(!resultMap.containsKey('doWorkPartial'))
          resultMap.put('doWorkPartial',new Map<String,Object>());
        resultMap.get('doWorkPartial').put(work.toString(),e);
      }
		}
	}

	private void publishAfterEventsPartial(Map<String,Map<String,Object>> resultMap)
	{
		resultMap.put('publishAfterEvents',new Map<String,Object>());
		for (Schema.SObjectType sObjectType : m_sObjectTypes)
		{
			m_dmlp.eventPublish(m_publishAfterListByType.get(sObjectType.getDescribe().getName()));
            resultMap.get('publishAfterEvents').put(
                sObjectType.getDescribe().getName()
                ,m_dmlp.eventPublish(m_publishAfterListByType.get(sObjectType.getDescribe().getName()))
            );
		}
	}
}
