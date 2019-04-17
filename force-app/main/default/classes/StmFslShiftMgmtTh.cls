public with sharing class StmFslShiftMgmtTh extends AbstractFslShiftMgmt {
    public List<ServiceTerritoryMember> newList;
    public List<ServiceTerritoryMember> oldList;
    public Map<Id, ServiceTerritoryMember> newMap;
    public Map<Id, ServiceTerritoryMember> oldMap;

    public StmFslShiftMgmtTh(List<ServiceTerritoryMember> newList, Boolean isDelete) {
        if(!isDelete) {
            this.newList = newList;
        } else {
            this.oldList = newList;
        }
    }

    public StmFslShiftMgmtTh(Map<Id, ServiceTerritoryMember> newMap
                             , Map<Id, ServiceTerritoryMember> oldMap) {
        this.newMap = newMap;
        this.oldMap = oldMap;
    }

    public void execute() {
        if(recurse_handler)
            { return; }

        if(newList != null && !newList.isEmpty()) {
            recurse_handler = true;
            
            execute(newList);

            return;
        } else if (oldList != null && !oldList.isEmpty()) {
            recurse_handler = true;
            
            doDelete(new Map<Id, ServiceTerritoryMember> (oldList));

            return;
        } else {
            recurse_handler = true;
            execute(newMap, oldMap);
        }
    }


    public void execute(Map<Id, ServiceTerritoryMember> recordsToProcess
                        , Map<Id, ServiceTerritoryMember> recordsToDelete) {
        doDelete(recordsToDelete);
        execute(recordsToProcess.values());
    }


    public void doDelete(Map<Id, ServiceTerritoryMember> recordsToDelete) {
        Set<String> shiftIds = new Set<String>();

        for(Id i : recordsToDelete.keySet())
            { shiftIds.add(recordsToDelete.get(i).Shift_ID__c); }
        
        try {
            delete [SELECT Id
                    FROM Event
                    WHERE Shift_ID__c IN :shiftIds];
        } catch (Exception e) {
            // throw error to user
            throw new StmFslShiftMgmtThException('Error deleting records!' + e.getMessage());
        }
    }

    public void execute(List<ServiceTerritoryMember> recordsToProcess) {
        Map<String, Schema.RecordTypeInfo> eventRecordTypeInfo
            = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName();        
        Id rtypeId = eventRecordTypeInfo.get(SHIFT_MANAGEMENT_RECORD_TYPE_NAME).getRecordTypeId();

        List<Event> eventsToInsert = new List<Event>();
        Set<Id> srIds = new Set<Id>();

        for(ServiceTerritoryMember i : recordsToProcess)
            { srIds.add(i.ServiceResourceId); }

        Map<Id, ServiceResource> srIdToServiceResource
            = new Map<Id, ServiceResource>([SELECT Id, RelatedRecordId
                                            FROM ServiceResource
                                            WHERE Id
                                            IN :srIds]);

        for(ServiceTerritoryMember i : recordsToProcess) {
            String shiftId = String.valueOf(i.ServiceResourceId)
                + String.valueOf(i.ServiceTerritoryId)
                + String.valueOf(i.OperatingHoursId)
                + String.valueOf(i.EffectiveStartDate)
                + String.valueOf(i.EffectiveEndDate);

            i.Shift_ID__c = shiftId;

            eventsToInsert.add(new Event(OwnerId = srIdToServiceResource.get(i.ServiceResourceId).RelatedRecordId
                                         , StartDateTime = i.EffectiveStartDate
                                         , EndDateTime = i.EffectiveEndDate
                                         , Operating_Hours__c = i.OperatingHoursId
                                         , Service_Territory__c = i.ServiceTerritoryId
                                         , RecordTypeId = rtypeId
                                         , Shift_ID__c = shiftId
                                         , Subject = DEFAULT_EVENT_SUBJECT));
        }

        try {
            insert eventsToInsert;
        } catch (Exception e) {
            throw new StmFslShiftMgmtThException('Error saving Event records! '
                                                 + e.getMessage());
        }
    }

    public class StmFslShiftMgmtThException extends Exception {}
}
