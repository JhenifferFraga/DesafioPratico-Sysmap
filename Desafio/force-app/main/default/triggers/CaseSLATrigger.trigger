trigger CaseSLATrigger on Case (before insert, before update) {
    CaseSLAHandler.handleSLACalculation(Trigger.new, Trigger.oldMap, Trigger.isInsert, Trigger.isUpdate);
}