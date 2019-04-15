trigger EventFslShiftMmgmtTrigger on Event (before insert
                                            , before update
                                            , before delete) {
    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            EventFslShiftMgmtTh(Trigger.new);
        } else if (Trigger.isUpdate) {
            EventFslShiftMgmtTh(Trigger.newMap, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            EventFslShiftMgmtTh(Trigger.old);
        }
    }
}
