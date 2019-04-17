public with sharing class EventFslShiftMgmtTh extends AbstractFslShiftMgmt {
    private List<Event> newList;
    private List<Event> oldList;
    private Map<Id, Event> newMap;
    private Map<Id, Event> oldMap;

    
    

    public EventFslShiftMgmtTh(List<Event> trigList, Boolean isDelete) {
        if(!isDelete) {
            this.newList = trigList;
        } else {
            this.oldList = trigList;
        }
    }

    public EventFslShiftMgmtTh(Map<Id, Event> newMap, Map<Id, Event> oldMap) {
        this.newMap = newMap;
        this.oldMap = oldMap;
    }


    public void execute() {
        if(recurse_handler)
            { return; }
        
        if(newList != null && !newList.isEmpty()) {
            recurse_handler = true;

            List<Event> toProcess = filter(newList);
            
            if(!toProcess.isEmpty())
                { execute(toProcess); }

     
            return;
        } else if (oldList != null && !oldList.isEmpty()) {
            recurse_handler = true;
            
            List<Event> toProcess = filter(oldList);

            if(!toProcess.isEmpty())
                { doDelete(new Map<Id, Event> (toProcess) ); }

            return;
        } else {
            recurse_handler = true;
            
            filter();
            execute(newMap, oldMap);
        }
    }

    public List<Event> filter(List<Event> e) {
        Map<String, Schema.RecordTypeInfo> eventRecordTypeInfo
            = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName();
        Id rtypeId = eventRecordTypeInfo.get(SHIFT_MANAGEMENT_RECORD_TYPE_NAME).getRecordTypeId();

        List<Event> toReturn = new List<Event>();

        for(Event i : e) {
            if(i.RecordTypeId == rtypeId)
                { toReturn.add(i); }
        }

        return toReturn;
    }

    public void filter() {
        Map<String, Schema.RecordTypeInfo> eventRecordTypeInfo
            = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName();        
        Id rtypeId = eventRecordTypeInfo.get(SHIFT_MANAGEMENT_RECORD_TYPE_NAME).getRecordTypeId();

        for(Event i : newMap.values()) {
            if(i.RecordTypeId != rtypeId) {
                newMap.remove(i.Id);
                oldMap.remove(i.Id);
                continue;
            }
        }
    }


    public void execute(Map<Id, Event> recordsToProcess
                        , Map<Id, Event> recordsToDelete) {
        doDelete(recordsToDelete);

        execute(recordsToProcess.values());
    }


    public void doDelete(Map<Id, Event> recordsToDelete) {
        Set<String> shiftIds = new Set<String>();

        for(Id i : recordsToDelete.keySet()) {
            Event thisEvent = recordsToDelete.get(i);
            shiftIds.add(thisEvent.Shift_ID__c);
        }
        
        try {
            delete [SELECT Id
                    FROM ServiceTerritoryMember
                    WHERE Shift_ID__c IN :shiftIds];
        } catch (Exception e) {
            // throw error to user
            throw new EventFslShiftMgmtThException('Error deleting records!' + e.getMessage());
        }
    }


    public void execute(List<Event> recordsToProcess) {
        List<ServiceTerritoryMember> stmsToInsert = new List<ServiceTerritoryMember>();
        Set<Id> userIds = new Set<Id>();
        Map<Id, Id> userIdToSrId = new Map<Id, Id> ();
        
        for(Event i : recordsToProcess)
            { userIds.add(i.OwnerId); }

        Map<Id, ServiceResource> srIdToServiceResource
            = new Map<Id, ServiceResource>([SELECT Id, RelatedRecordId
                                            FROM ServiceResource
                                            WHERE RelatedRecordId
                                            IN :userIds]);
        for(Id i : srIdToServiceResource.keySet())
            { userIdToSrId.put(srIdToServiceResource.get(i).RelatedRecordId, i); }

        for(Event i : recordsToProcess) {
            String shiftId = String.valueOf(userIdToSrId.get(i.OwnerId))
                + String.valueOf(i.Service_Territory__c)
                + String.valueOf(i.Operating_Hours__c)
                + String.valueOf(i.StartDateTime)
                + String.valueOf(i.EndDateTime);


            i.Shift_ID__c = shiftId;

            stmsToInsert.add(new ServiceTerritoryMember(ServiceTerritoryId = i.Service_Territory__c
                                                        , OperatingHoursId = i.Operating_Hours__c
                                                        , EffectiveStartDate = i.StartDateTime
                                                        , EffectiveEndDate = i.EndDateTime
                                                        , Shift_Id__c = shiftId
                                                        , ServiceResourceId = userIdToSrId.get(i.OwnerId)));
        }

        
        try {
            insert stmsToInsert;
        } catch (Exception e) {
            throw new EventFslShiftMgmtThException('Error Saving Service Territory Member Records!'
                                                   + e.getMessage());
        }
    }

    public class EventFslShiftMgmtThException extends Exception {}
}
