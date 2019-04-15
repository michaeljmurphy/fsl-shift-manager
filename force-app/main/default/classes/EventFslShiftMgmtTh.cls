public with sharing class EventFslShiftMgmtTh {
    List<Event> _newList;
    List<Event> _oldList;
    Map<Id, Event> _newMap;
    Map<Id, Event> _oldMap;
    Map<Id, Event> _recordsToProcess;


    public EventFslShiftMgmtTh(List<Event> trigList, Boolean isDelete) {
        if(isDelete) {
            this._newList = trigList;
        } else {
            this._oldList = trigList;
        }
    }

    public EventFslShiftMgmtTh(Map<Id, Event> newMap, Map<Id, Event> oldMap) {
        this._newMap = newMap;
        this._oldMap = oldMap;
    }


    public void filterRecords() {
        if(_newList != null && !_newList.isBlank()) {
            execute(genMapFromList(_newList));
            return;
        } else if(_oldList != null && !_oldList.isBlank()) {
            execute(genMapFromList(_oldList));
            return;
        }

        execute(_newMap, _oldMap);
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
                    WHERE Shift_ID__c
                    IN :shiftIds];
        } catch (Exception e) {
            Databse.rollback(sp);
            
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

        Map<Id, ServiceResource> srIdToServiceResource = ([SELECT Id, RelatedRecordId
                                                           FROM ServiceResource
                                                           WHERE RelatedRecordId
                                                           IN :userIds]);
        for(Id i : srIdToServiceResource.keySet())
            { userIdToSrId.put(srIdToServiceResource.get(i).RelatedRecordId, i); }

        for(Id i : recordsToProcess.keySet()) {
            Event thisEvent = recordsToProcess.get(i);

            thisEvent.Shift_ID__c = userIdToSrId.get(thisEvent.OwnerId)
                + thisEvent.Service_Territory__c
                + thisEvent.Operating_Hours__c
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
