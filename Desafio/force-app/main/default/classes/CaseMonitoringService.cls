public class CaseMonitoringService {
    
    @InvocableMethod(label='Verificar SLA do Caso' description='Retorna informacoes sobre o SLA do caso')
    public static List<SLAResult> checkCaseSLA(List<SLARequest> requests) {
        List<SLAResult> results = new List<SLAResult>();
        
        for (SLARequest request : requests) {
            SLAResult result = new SLAResult();
            
            // Procura pelo caso
            List<Case> cases = [SELECT Id, CaseNumber, DataLimiteResolucao__c, Status 
                               FROM Case 
                               WHERE Id = :request.caseId 
                               LIMIT 1];
            
            if (cases.isEmpty()) {
                result.errorMessage = 'Caso não encontrado';
                results.add(result);
                continue;
            }
            
            Case caso = cases[0];
            DateTime dataLimite = caso.DataLimiteResolucao__c;
            DateTime now = DateTime.now();
            
            if (dataLimite != null) {
                Long difference = dataLimite.getTime() - now.getTime();
                
                if (difference > 0) {

                    Long hours = difference / (1000 * 60 * 60);
                    Long totalMinutes = difference / (1000 * 60);
                    Long minutes = totalMinutes - (hours * 60);
                    result.remainingTime = hours + ' horas e ' + minutes + ' minutos';
                    result.isOverdue = false;
                } else {

                    Long positiveDifference = Math.abs(difference);
                    Long overdueHours = positiveDifference / (1000 * 60 * 60);
                    Long totalOverdueMinutes = positiveDifference / (1000 * 60);
                    Long overdueMinutes = totalOverdueMinutes - (overdueHours * 60);
                    result.alertMessage = 'ATENÇÃO: Caso vencido a ' + overdueHours + ' horas e ' + overdueMinutes + ' minutos!';
                    result.isOverdue = true;
                }
            } else {
                result.errorMessage = 'Prazo de resolução não definido para este caso.';
            }
            
            result.caseNumber = caso.CaseNumber;
            result.status = caso.Status;
            results.add(result);
        }
        
        return results;
    }
    
    // Classes internas para entrada e saída
    public class SLARequest {
        @InvocableVariable(required=true)
        public String caseId;
    }
    
    public class SLAResult {
        @InvocableVariable
        public String caseNumber;
        
        @InvocableVariable
        public String status;
        
        @InvocableVariable
        public String remainingTime;
        
        @InvocableVariable
        public String alertMessage;
        
        @InvocableVariable
        public String errorMessage;
        
        @InvocableVariable
        public Boolean isOverdue;
    }
}