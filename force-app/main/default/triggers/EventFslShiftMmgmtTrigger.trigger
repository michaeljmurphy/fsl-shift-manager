trigger EventFslShiftMmgmtTrigger on Event (before insert
                                            , before update
                                            , before delete) {
    if(Trigger.isBefore) {
        EventFslShiftMgmtTh e;
        if(Trigger.isInsert) {
            e = new EventFslShiftMgmtTh(Trigger.new, false);
        } else if (Trigger.isUpdate) {
            e = new EventFslShiftMgmtTh(Trigger.newMap, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            e = new EventFslShiftMgmtTh(Trigger.old, true);
        }

        e.execute();
    }
}
