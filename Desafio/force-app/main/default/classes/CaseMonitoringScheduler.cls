public class CaseMonitoringScheduler implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        // Executar o batch de monitoramento
        CaseMonitoringBatch batch = new CaseMonitoringBatch();
        Database.executeBatch(batch, 200); // Processar até 200 registros por vez
    }
    
    // Método utilitário para agendar a execução
    public static void scheduleMonitoring() {
        // Cancelar jobs anteriores se existirem
        List<CronTrigger> existingJobs = [
            SELECT Id FROM CronTrigger 
            WHERE CronJobDetail.Name LIKE 'Case SLA Monitoring%'
        ];
        
        for (CronTrigger job : existingJobs) {
            System.abortJob(job.Id);
        }
        
        // Como não podemos usar */5, vamos agendar múltiplos jobs
        // para executar nos minutos 0, 5, 10, 15, etc.
        List<String> minutes = new List<String>{'0', '5', '10', '15', '20', '25', '30', '35', '40', '45', '50', '55'};
        
        CaseMonitoringScheduler scheduler = new CaseMonitoringScheduler();
        
        for(Integer i = 0; i < minutes.size(); i++) {
            String cronExp = '0 ' + minutes[i] + ' * * * ?'; // Todo dia, toda hora, no minuto especificado
            String jobName = 'Case SLA Monitoring ' + minutes[i];
            System.schedule(jobName, cronExp, scheduler);
        }
        
        System.debug('Jobs de monitoramento agendados com sucesso (12 jobs - a cada 5 minutos)');
    }
    
    // Método para executar manualmente (útil para testes)
    public static void executeNow() {
        CaseMonitoringBatch batch = new CaseMonitoringBatch();
        Database.executeBatch(batch, 200);
        System.debug('Batch executado manualmente');
    }
}