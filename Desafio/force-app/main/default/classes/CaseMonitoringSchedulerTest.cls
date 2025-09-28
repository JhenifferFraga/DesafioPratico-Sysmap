@IsTest
private class CaseMonitoringSchedulerTest {

    @IsTest
    static void testExecuteNowRunsBatch() {
        Case c = new Case(
            Subject='Scheduler Test',
            Status='New',
            Urgencia__c='Média',
            MotivoDoCaso__c='Lentidão'
        );
        insert c;

        c = [SELECT Id, DataLimiteResolucao__c FROM Case WHERE Id=:c.Id];
        c.DataLimiteResolucao__c = System.now().addMinutes(-10);
        update c;

        Test.startTest();
        CaseMonitoringScheduler.executeNow();
        Test.stopTest();

        Case updated = [SELECT Urgencia__c FROM Case WHERE Id=:c.Id];
        System.assertEquals('Alta', updated.Urgencia__c,
            'executeNow deveria rodar batch e elevar urgência');
    }


    @IsTest
    static void testScheduleMonitoringCreatesAndAbortsJobs() {
        Test.startTest();
        CaseMonitoringScheduler.scheduleMonitoring();
        CaseMonitoringScheduler.scheduleMonitoring();
        Test.stopTest();

        List<CronTrigger> jobs =
            [SELECT Id, CronJobDetail.Name FROM CronTrigger
             WHERE CronJobDetail.Name LIKE 'Case SLA Monitoring%'];
        System.assert(!jobs.isEmpty(),
            'scheduleMonitoring deveria criar jobs "Case SLA Monitoring"');
    }
}