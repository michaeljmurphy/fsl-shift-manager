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


    public void execute(Map<Id, Event> recordsToDelete
                        , Map<Id, Event> recordsToProcess) {
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
        for(Id i : recordsToProcess.keySet()) {
            
        }
    }

    public class EventFslShiftMgmtThException extends Exception {}
}
