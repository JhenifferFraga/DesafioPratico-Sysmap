public class CaseSLAHandler {
    
    public static void handleSLACalculation(List<Case> newCases, Map<Id, Case> oldCaseMap, Boolean isInsert, Boolean isUpdate) {
        
        Map<String, Integer> slaMap = new Map<String, Integer>();        
        for (SLA__mdt sla : [SELECT Urgencia__c, MinutosParaResolucao__c FROM SLA__mdt]) {
            slaMap.put(sla.Urgencia__c, Integer.valueOf(sla.MinutosParaResolucao__c));
        }
        
        for (Case caso : newCases) {
            
            if (isInsert || 
                (isUpdate && caso.Urgencia__c != oldCaseMap.get(caso.Id).Urgencia__c)) {
                
                if (caso.Urgencia__c != null && slaMap.containsKey(caso.Urgencia__c)) {
                    Integer minutes = slaMap.get(caso.Urgencia__c);
                    caso.DataLimiteResolucao__c = DateTime.now().addMinutes(minutes);
                }
            }
        }
    }
}