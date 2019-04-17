trigger StmFslShiftMgmtTrigger on ServiceTerritoryMember (before insert, before update, before delete) {
    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
             
        } else if (Trigger.isUpdate) {
            
        } else if (Trigger.isDelete) {
            
        }
    }
}
