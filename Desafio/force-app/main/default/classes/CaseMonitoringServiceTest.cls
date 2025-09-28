@IsTest
private class CaseMonitoringServiceTest {
    @IsTest
    static void testCheckCaseSLAWithinDeadline() {
        Case c = new Case(
            Subject='Service Test',
            Status='New',
            Urgencia__c='Média',
            MotivoDoCaso__c='Lentidão',
            DataLimiteResolucao__c=System.now().addHours(1)
        );
        insert c;
        
        CaseMonitoringService.SLARequest req = new CaseMonitoringService.SLARequest();
        req.caseId = c.Id;
        
        Test.startTest();
        List<CaseMonitoringService.SLAResult> res =
            CaseMonitoringService.checkCaseSLA(new List<CaseMonitoringService.SLARequest>{req});
        Test.stopTest();
        
        System.assertEquals(false, res[0].isOverdue, 'Não deveria estar atrasado');
        System.assert(res[0].remainingTime != null && res[0].remainingTime.contains('hora'), 'Deveria trazer tempo restante');
    }
    
    @IsTest
    static void testCheckCaseSLAOverdue() {
        Case c = new Case(
            Subject='Overdue Test',
            Status='Working',
            Urgencia__c='Baixa',
            MotivoDoCaso__c='Problema de Rede'
        );
        insert c;

        c = [SELECT Id, DataLimiteResolucao__c, Urgencia__c FROM Case WHERE Id = :c.Id];
        c.DataLimiteResolucao__c = System.now().addHours(-2);
        update c;

        CaseMonitoringService.SLARequest req = new CaseMonitoringService.SLARequest();
        req.caseId = c.Id;

        Test.startTest();
        List<CaseMonitoringService.SLAResult> res =
            CaseMonitoringService.checkCaseSLA(new List<CaseMonitoringService.SLARequest>{ req });
        Test.stopTest();

        System.assertEquals(true, res[0].isOverdue, 'Deveria estar atrasado');
        System.assertNotEquals(null, res[0].alertMessage, 'Mensagem de alerta deveria ser preenchida');
    }
}