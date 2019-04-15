public with sharing class EventFslShiftMgmtTh {
    List<Event> newList;
    List<Event> oldList;
    Map<Id, Event> newMap;
    Map<Id, Event> oldMap;


    public EventFslShiftMgmtTh(List<Event> trigList, Boolean isDelete) {
        if(isDelete) {
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
        if(newList != null && !newList.isEmpty()) {
            execute(new Map<Id, Event> ( newList ));
            return;
        } else if(oldList != null && !oldList.isEmpty()) {
            execute(new Map<Id, Event> ( oldList ));
            return;
        }

        execute(newMap, oldMap);
    }


    public void execute(Map<Id, Event> recordsToProcess
                        , Map<Id, Event> recordsToDelete) {
        SavePoint sp = Database.setSavePoint();

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
            Database.rollback(sp);
            
            // throw error to user
            throw new EventFslShiftMgmtThException('Error deleting records!');
        }

        execute(recordsToProcess);
    }

    public void execute(Map<Id, Event> recordsToProcess) {

        List<ServiceTerritoryMember> stmsToInsert = new List<ServiceTerritoryMember>();
        Set<Id> userIds = new Set<Id>();
        Map<Id, Id> userIdToSrId = new Map<Id, Id> ();
        
        for(Event i : recordsToProcess.values())
            { userIds.add(i.OwnerId); }

        Map<Id, ServiceResource> srIdToServiceResource
            = new Map<Id, ServiceResource>([SELECT Id, RelatedRecordId
                                            FROM ServiceResource
                                            WHERE RelatedRecordId
                                            IN :userIds]);
        for(Id i : srIdToServiceResource.keySet())
            { userIdToSrId.put(srIdToServiceResource.get(i).RelatedRecordId, i); }

        for(Id i : recordsToProcess.keySet()) {
            Event thisEvent = recordsToProcess.get(i);

            thisEvent.Shift_ID__c = String.valueOf(userIdToSrId.get(thisEvent.OwnerId))
                + String.valueOf(thisEvent.Service_Territory__c)
                + String.valueOf(thisEvent.Operating_Hours__c)
                + String.valueOf(thisEvent.StartDateTime)
                + String.valueOf(thisEvent.EndDateTime);

            stmsToInsert.add(new ServiceTerritoryMember(ServiceTerritoryId = thisEvent.Service_Territory__c
                                                        , OperatingHoursId = thisEvent.Operating_Hours__c
                                                        , ServiceResourceId = userIdToSrId.get(thisEvent.OwnerId)));

            try {
                insert stmsToInsert;
            } catch (Exception e) {
                throw new EventFslShiftMgmtThException('Error Saving Service Territory Member Records!'
                                                       + e.getMessage());
            }
        }
    }

    public class EventFslShiftMgmtThException extends Exception {}
}
