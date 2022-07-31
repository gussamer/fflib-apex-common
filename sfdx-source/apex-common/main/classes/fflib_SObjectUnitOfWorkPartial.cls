public virtual class fflib_SObjectUnitOfWorkPartial
    extends fflib_SObjectUnitOfWork
    implements fflib_ISObjectUnitOfWorkPartial 
{
    protected Map<String, List<SObject>> m_publishAfterListByType = new Map<String, List<SObject>>();
    @TestVisible protected List<Messaging.Email> m_emailWorkPartial = new List<Messaging.Email>();
    protected List<IDoWorkPartial> m_workListPartial = new List<IDoWorkPartial>();
    protected IDMLP m_dmlp;
    public IResponse m_resp;
    /**
     * Constructs a new UnitOfWork to support work against the given object list
     *
     * @param sObjectTypes A list of objects given in dependency order (least dependent first)
     */
    public fflib_SObjectUnitOfWorkPartial(List<Schema.SObjectType> sObjectTypes)
    {
        this(sObjectTypes,new SimpleDMLPartial(),new Response(sObjectTypes));
    }
    public fflib_SObjectUnitOfWorkPartial(List<Schema.SObjectType> sObjectTypes, IResponse resp)
    {
        this(sObjectTypes,new SimpleDMLPartial(),resp);
    }
    public fflib_SObjectUnitOfWorkPartial(List<Schema.SObjectType> sObjectTypes, IDMLP dml)
    {
        this(sObjectTypes,dml,new Response(sObjectTypes));
    }
    public fflib_SObjectUnitOfWorkPartial(List<Schema.SObjectType> sObjectTypes, fflib_SObjectUnitOfWork.IDML dml)
    {
        super(sObjectTypes,dml);
        m_dmlp = new SimpleDMLPartial();
        m_resp = new Response(sObjectTypes);
        for (Schema.SObjectType sObjectType : m_sObjectTypes)
        {
            handleRegisterTypePartial(sObjectType);
        }
    }
    public fflib_SObjectUnitOfWorkPartial(List<Schema.SObjectType> sObjectTypes, IDMLP dml, IResponse resp)
    {
        super(sObjectTypes);
        m_dmlp = dml;
        m_resp = resp;
        for (Schema.SObjectType sObjectType : m_sObjectTypes)
        {
            handleRegisterTypePartial(sObjectType);
        }
    }
    /***
     * virtuals
     */
    public virtual void onRegisterTypePartial(Schema.SObjectType sObjectType) {
        onRegisterType(sObjectType);
    }
    public virtual void onCommitWorkStartingPartial(IResponse resp) {
        onCommitWorkStarting();
    }
    public virtual void onPublishBeforeEventsStartingPartial(IResponse resp) {
        onPublishBeforeEventsStarting();
    }
    public virtual void onPublishBeforeEventsFinishedPartial(IResponse resp) {
        onPublishBeforeEventsFinished();
    }
    public virtual void onDMLStartingPartial(IResponse resp) {
        onDMLStarting();
    }
    public virtual void onDMLFinishedPartial(IResponse resp) {
        onDMLFinished();
    }
    public virtual void onDoWorkStartingPartial(IResponse resp) {
        onDoWorkStarting();
    }
    public virtual void onDoWorkFinishedPartial(IResponse resp) {
        onDoWorkFinished();
    }
    public virtual void onPublishAfterEventsStartingPartial(IResponse resp) {
        onPublishAfterSuccessEventsStarting();
    }
    public virtual void onPublishAfterEventsFinishedPartial(IResponse resp) {
        onPublishAfterSuccessEventsFinished();
    }
    public virtual void onCommitWorkFinishingPartial(IResponse resp) {
        onCommitWorkFinishing();
    }
    public virtual void onCommitWorkFinishedPartial(IResponse resp) {}

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
     * Registers the given email to be sent during the commitWork
     **/
    public void registerEmailPartial(Messaging.Email email)
    {
        m_emailWorkPartial.add(email);
    }
    /**
     * Takes all the work that has been registered with the UnitOfWork and commits it to the database with allOrNone set a passed
     **/
    public IResponse commitWork(Boolean allOrNone){
        if(allOrNone){
            this.commitWork();
            return null;
        }else{
            m_resp = new Response();
            doCommitWork(m_resp);
            doAfterCommitWorkStepsPartial(m_resp);
            return m_resp;
        }
    }

	private void doCommitWork(IResponse resp)
	{
		onCommitWorkStartingPartial(resp);
		onPublishBeforeEventsStartingPartial(resp);
		publishBeforeEventsPartial(resp);
		onPublishBeforeEventsFinishedPartial(resp);

		onDMLStartingPartial(resp);
		insertDmlByTypePartial(resp);
		updateDmlByTypePartial(resp);
		deleteDmlByTypePartial(resp);
		emptyRecycleBinByTypePartial(resp);
		resolveEmailRelationships();
        emailWorkPartial(resp);
		onDMLFinishedPartial(resp);

		onDoWorkStartingPartial(resp);
		doWorkPartial(resp);
		onDoWorkFinishedPartial(resp);
		onCommitWorkFinishingPartial(resp);
	}

	private void doAfterCommitWorkStepsPartial(IResponse resp)
	{
		doAfterCommitWorkAfterStepsPartial(resp);
        onCommitWorkFinishedPartial(resp);
	}

	private void doAfterCommitWorkAfterStepsPartial(IResponse resp)
	{
		onPublishAfterEventsStartingPartial(resp);
		publishAfterEventsPartial(resp);
		onPublishAfterEventsFinishedPartial(resp);
	}

	private void publishBeforeEventsPartial(IResponse resp)
	{
        for (Schema.SObjectType sObjectType : m_sObjectTypes)
		{
			resp.addPublishBeforeEvents(
                sObjectType
                ,m_dmlp.eventPublish(m_publishBeforeListByType.get(sObjectType.getDescribe().getName()))
            );
		}
	}

	private void insertDmlByTypePartial(IResponse resp)
	{
		for (Schema.SObjectType sObjectType : m_sObjectTypes)
		{
			m_relationships.get(sObjectType.getDescribe().getName()).resolve();
            resp.addInsertDmlByType(
                sObjectType
                ,m_dmlp.dmlInsert(m_newListByType.get(sObjectType.getDescribe().getName()))
            );
		}
	}

	private void updateDmlByTypePartial(IResponse resp)
	{
		for (Schema.SObjectType sObjectType : m_sObjectTypes)
		{
            resp.addUpdateDmlByType(
                sObjectType
                ,m_dmlp.dmlUpdate(m_dirtyMapByType.get(sObjectType.getDescribe().getName()).values())
            );
		}
	}

	private void deleteDmlByTypePartial(IResponse resp)
	{
		Integer objectIdx = m_sObjectTypes.size() - 1;
		while (objectIdx >= 0)
		{
            resp.addDeleteDmlByType(
                m_sObjectTypes[objectIdx]
                ,m_dmlp.dmlDelete(m_deletedMapByType.get(m_sObjectTypes[objectIdx--].getDescribe().getName()).values())
            );
		}
	}

	private void emptyRecycleBinByTypePartial(IResponse resp)
	{
		Integer objectIdx = m_sObjectTypes.size() - 1;
		while (objectIdx >= 0)
		{
            resp.addEmptyRecycleBinByType(
                m_sObjectTypes[objectIdx]
                ,m_dmlp.emptyRecycleBin(m_emptyRecycleBinMapByType.get(m_sObjectTypes[objectIdx--].getDescribe().getName()).values())
            );
		}
	}

	private void emailWorkPartial(IResponse resp)
	{
		resp.addSendEmailWork(m_dmlp.sendEmail(m_emailWorkPartial));
	}

    private String getWorkName(IDoWorkPartial work){
        return work.toString().left(work.toString().indexOf(':'));
    }

	private void doWorkPartial(IResponse resp)
	{
		for (IDoWorkPartial work : m_workListPartial)
		{
            try{
                resp.addDoWorkPartialResults(getWorkName(work),work.doWork());
            }catch(Exception e){
                resp.addDoWorkPartialFailures(getWorkName(work),e);
            }
		}
	}

	private void publishAfterEventsPartial(IResponse resp)
	{
		for (Schema.SObjectType sObjectType : m_sObjectTypes)
		{
            resp.addPublishAfterEvents(
                sObjectType
                ,m_dmlp.eventPublish(m_publishAfterListByType.get(sObjectType.getDescribe().getName()))
            );
		}
	}
    /**
     * Interface describes work to be performed during the commitWork method
     **/
    public interface IDoWorkPartial
    {
        Object doWork();
    }
    
    public interface IDMLP
    {
        List<Database.SaveResult> dmlInsert(List<SObject> objList);
        List<Database.SaveResult> dmlUpdate(List<SObject> objList);
        List<Database.DeleteResult> dmlDelete(List<SObject> objList);
        List<Database.SaveResult> eventPublish(List<SObject> objList);
        List<Database.EmptyRecycleBinResult> emptyRecycleBin(List<SObject> objList);
        List<Messaging.SendEmailResult> sendEmail(List<Messaging.Email> emailList);
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
        public virtual List<Messaging.SendEmailResult> sendEmail(List<Messaging.Email> emails)
        {
            return Messaging.sendEmail(emails,false);
        }
    }

    public interface IResponse 
    {
        void handleRegisterType(Schema.SObjectType sObjectType);
        void addPublishBeforeEvents(Schema.SObjectType sObjectType,List<Database.SaveResult> results);
        void addInsertDmlByType(Schema.SObjectType sObjectType,List<Database.SaveResult> results);
        void addUpdateDmlByType(Schema.SObjectType sObjectType,List<Database.SaveResult> results);
        void addDeleteDmlByType(Schema.SObjectType sObjectType,List<Database.DeleteResult> results);
        void addEmptyRecycleBinByType(Schema.SObjectType sObjectType,List<Database.EmptyRecycleBinResult> results);
        void addSendEmailWork(List<Messaging.SendEmailResult> results);
        void addPublishAfterEvents(Schema.SObjectType sObjectType,List<Database.SaveResult> results);
        void addDoWorkPartialResults(String doWorkName,Object results);
        void addDoWorkPartialFailures(String doWorkName,Exception results);
        Map<Schema.SObjectType,List<Database.SaveResult>> getPublishBeforeEvents();
        Map<Schema.SObjectType,List<Database.SaveResult>> getInsertDmlByType();
        Map<Schema.SObjectType,List<Database.SaveResult>> getUpdateDmlByType();
        Map<Schema.SObjectType,List<Database.DeleteResult>> getDeleteDmlByType();
        Map<Schema.SObjectType,List<Database.EmptyRecycleBinResult>> getEmptyRecycleBinByType();
        List<Messaging.SendEmailResult> getSendEmailWork();
        Map<Schema.SObjectType,List<Database.SaveResult>> getPublishAfterEvents();
        Map<String,Object> getDoWorkPartialResults();
        Map<String,Exception> getDoWorkPartialFailures();
    }
    
    public virtual class Response implements IResponse
    {
        Map<Schema.SObjectType,List<Database.SaveResult>> publishBeforeEvents;
        Map<Schema.SObjectType,List<Database.SaveResult>> insertDmlByType;
        Map<Schema.SObjectType,List<Database.SaveResult>> updateDmlByType;
        Map<Schema.SObjectType,List<Database.DeleteResult>> deleteDmlByType;
        Map<Schema.SObjectType,List<Database.EmptyRecycleBinResult>> emptyRecycleBinByType;
        List<Messaging.SendEmailResult> sendEmailWork;
        Map<Schema.SObjectType,List<Database.SaveResult>> publishAfterEvents;
        Map<String,Object> doWorkPartialResults;
        Map<String,Exception> doWorkPartialFailures;
        public Response()
        {
            publishBeforeEvents = new Map<Schema.SObjectType,List<Database.SaveResult>>();
            insertDmlByType = new Map<Schema.SObjectType,List<Database.SaveResult>>();
            updateDmlByType = new Map<Schema.SObjectType,List<Database.SaveResult>>();
            deleteDmlByType = new Map<Schema.SObjectType,List<Database.DeleteResult>>();
            emptyRecycleBinByType = new Map<Schema.SObjectType,List<Database.EmptyRecycleBinResult>>();
            sendEmailWork = new List<Messaging.SendEmailResult>();
            publishAfterEvents = new Map<Schema.SObjectType,List<Database.SaveResult>>();
            doWorkPartialResults = new Map<String,Object>();
            doWorkPartialFailures = new Map<String,Exception>();
        }
        public Response(List<Schema.SObjectType> sObjectTypes)
        {
            publishBeforeEvents = new Map<Schema.SObjectType,List<Database.SaveResult>>();
            insertDmlByType = new Map<Schema.SObjectType,List<Database.SaveResult>>();
            updateDmlByType = new Map<Schema.SObjectType,List<Database.SaveResult>>();
            deleteDmlByType = new Map<Schema.SObjectType,List<Database.DeleteResult>>();
            emptyRecycleBinByType = new Map<Schema.SObjectType,List<Database.EmptyRecycleBinResult>>();
            sendEmailWork = new List<Messaging.SendEmailResult>();
            publishAfterEvents = new Map<Schema.SObjectType,List<Database.SaveResult>>();
            doWorkPartialResults = new Map<String,Object>();
            doWorkPartialFailures = new Map<String,Exception>();
            for(Schema.SObjectType sObjectType:sObjectTypes){
                handleRegisterType(sObjectType);
            }
        }
        public virtual void handleRegisterType(Schema.SObjectType sObjectType)
        {
            publishBeforeEvents.put(sObjectType,new List<Database.SaveResult>());
            insertDmlByType.put(sObjectType,new List<Database.SaveResult>());
            updateDmlByType.put(sObjectType,new List<Database.SaveResult>());
            deleteDmlByType.put(sObjectType,new List<Database.DeleteResult>());
            emptyRecycleBinByType.put(sObjectType,new List<Database.EmptyRecycleBinResult>());
            publishAfterEvents.put(sObjectType,new List<Database.SaveResult>());
        }
        public virtual void addPublishBeforeEvents(Schema.SObjectType sObjectType,List<Database.SaveResult> results)
        {
            publishBeforeEvents.put(sObjectType,results);
        }
        public virtual void addInsertDmlByType(Schema.SObjectType sObjectType,List<Database.SaveResult> results)
        {
            insertDmlByType.put(sObjectType,results);
        }
        public virtual void addUpdateDmlByType(Schema.SObjectType sObjectType,List<Database.SaveResult> results)
        {
            updateDmlByType.put(sObjectType,results);
        }
        public virtual void addDeleteDmlByType(Schema.SObjectType sObjectType,List<Database.DeleteResult> results)
        {
            deleteDmlByType.put(sObjectType,results);
        }
        public virtual void addEmptyRecycleBinByType(Schema.SObjectType sObjectType,List<Database.EmptyRecycleBinResult> results)
        {
            emptyRecycleBinByType.put(sObjectType,results);
        }
        public virtual void addSendEmailWork(List<Messaging.SendEmailResult> results)
        {
            sendEmailWork = results;
        }
        public virtual void addPublishAfterEvents(Schema.SObjectType sObjectType,List<Database.SaveResult> results)
        {
            publishAfterEvents.put(sObjectType,results);
        }
        public virtual void addDoWorkPartialResults(String doWorkName,Object results)
        {
            doWorkPartialResults.put(doWorkName,results);
        }
        public virtual void addDoWorkPartialFailures(String doWorkName,Exception results)
        {
            doWorkPartialFailures.put(doWorkName,results);
        }
        public virtual Map<Schema.SObjectType,List<Database.SaveResult>> getPublishBeforeEvents()
        {
            return publishBeforeEvents;
        }
        public virtual Map<Schema.SObjectType,List<Database.SaveResult>> getInsertDmlByType()
        {
            return insertDmlByType;
        }
        public virtual Map<Schema.SObjectType,List<Database.SaveResult>> getUpdateDmlByType()
        {
            return updateDmlByType;
        }
        public virtual Map<Schema.SObjectType,List<Database.DeleteResult>> getDeleteDmlByType()
        {
            return deleteDmlByType;
        }
        public virtual Map<Schema.SObjectType,List<Database.EmptyRecycleBinResult>> getEmptyRecycleBinByType()
        {
            return emptyRecycleBinByType;
        }
        public virtual List<Messaging.SendEmailResult> getSendEmailWork()
        {
            return sendEmailWork;
        }
        public virtual Map<Schema.SObjectType,List<Database.SaveResult>> getPublishAfterEvents()
        {
            return publishAfterEvents;
        }
        public virtual Map<String,Object> getDoWorkPartialResults()
        {
            return doWorkPartialResults;
        }
        public virtual Map<String,Exception> getDoWorkPartialFailures()
        {
            return doWorkPartialFailures;
        }
    }
}
