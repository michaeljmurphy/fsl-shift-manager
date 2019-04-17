trigger StmFslShiftMgmtTrigger on ServiceTerritoryMember (before insert, before update, before delete) {
    if(Trigger.isBefore) {
        StmFslShiftMgmtTh e;

        if(Trigger.isInsert) {
            e = new StmFslShiftMgmtTh(Trigger.new, false);
        } else if (Trigger.isUpdate) {
            e = new StmFslShiftMgmtTh(Trigger.newMap, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            e = new StmFslShiftMgmtTh(Trigger.old, true);
        }

        e.execute();
    }
}
