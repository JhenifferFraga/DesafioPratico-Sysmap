public class CaseMonitoringBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    // Lista para armazenar casos atrasados para o e-mail
    private List<Case> overdueCases = new List<Case>();
    
    // Query para buscar casos abertos que ultrapassaram o prazo
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, CaseNumber, Urgencia__c, DataLimiteResolucao__c, Owner.Name, 
                   Subject, CreatedDate, Status
            FROM Case 
            WHERE Status != 'Closed' 
            AND DataLimiteResolucao__c != null 
            AND DataLimiteResolucao__c < :DateTime.now()
            AND Urgencia__c != 'Alta'
        ]);
    }
    
    // Processar cada lote de casos
    public void execute(Database.BatchableContext bc, List<Case> scope) {
        List<Case> casesToUpdate = new List<Case>();
        
        for (Case caso : scope) {
            // Verificar se o caso realmente ultrapassou o prazo
            if (caso.DataLimiteResolucao__c < DateTime.now()) {
                // Alterar urgência para Alta
                caso.Urgencia__c = 'Alta';
                casesToUpdate.add(caso);
                
                // Adicionar à lista de casos atrasados para o e-mail
                overdueCases.add(caso);
            }
        }
        
        // Atualizar os casos
        if (!casesToUpdate.isEmpty()) {
            try {
                update casesToUpdate;
                System.debug('Casos atualizados para Alta urgência: ' + casesToUpdate.size());
            } catch (DmlException e) {
                System.debug('Erro ao atualizar casos: ' + e.getMessage());
            }
        }
    }
    
    // Após processar todos os lotes, enviar e-mail de notificação
    public void finish(Database.BatchableContext bc) {
        if (!overdueCases.isEmpty()) {
            sendOverdueNotification(overdueCases);
        }
        
        System.debug('Batch finalizado. Total de casos processados: ' + overdueCases.size());
    }
    
    // Método para enviar e-mail de notificação
    private void sendOverdueNotification(List<Case> cases) {
        // Buscar gerentes de suporte (usuários com perfil de Gerente)
        List<User> managers = [
            SELECT Id, Email, Name 
            FROM User 
            WHERE Profile.Name = 'Gerente de Suporte' 
            AND IsActive = true
        ];
        
        if (managers.isEmpty()) {
            System.debug('Nenhum gerente de suporte encontrado para envio do e-mail');
            return;
        }
        
        // Construir corpo do e-mail
        String emailBody = buildEmailBody(cases);
        
        // Enviar e-mail para cada gerente
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (User manager : managers) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{ manager.Email });
            email.setSubject('Alerta: Casos com SLA Vencido - ' + DateTime.now().format('dd/MM/yyyy HH:mm'));
            email.setHtmlBody(emailBody);
            emails.add(email);
        }
        
        // Enviar os e-mails
        try {
            Messaging.sendEmail(emails);
            System.debug('E-mails enviados com sucesso para ' + managers.size() + ' gerentes');
        } catch (Exception e) {
            System.debug('Erro ao enviar e-mails: ' + e.getMessage());
        }
    }
    
    // Construir o corpo do e-mail em HTML
    private String buildEmailBody(List<Case> cases) {
        String body = '<html><body>';
        body += '<h2>Alerta: Casos com SLA Vencido</h2>';
        body += '<p>Os seguintes casos ultrapassaram o prazo de resolução e tiveram sua urgência alterada para <strong>Alta</strong>:</p>';
        body += '<table border="1" style="border-collapse: collapse; width: 100%;">';
        body += '<tr style="background-color: #f2f2f2;">';
        body += '<th>Número do Caso</th><th>Assunto</th><th>Proprietário</th><th>Data Limite</th><th>Tempo em Atraso</th>';
        body += '</tr>';
        
        for (Case caso : cases) {
            Long delayMinutes = (DateTime.now().getTime() - caso.DataLimiteResolucao__c.getTime()) / (1000 * 60);
            String delayTime = formatDelay(delayMinutes);
            
            body += '<tr>';
            body += '<td>' + caso.CaseNumber + '</td>';
            body += '<td>' + (caso.Subject != null ? caso.Subject : 'Sem assunto') + '</td>';
            body += '<td>' + caso.Owner.Name + '</td>';
            body += '<td>' + caso.DataLimiteResolucao__c.format('dd/MM/yyyy HH:mm') + '</td>';
            body += '<td style="color: red; font-weight: bold;">' + delayTime + '</td>';
            body += '</tr>';
        }
        
        body += '</table>';
        body += '<p><strong>Total de casos atrasados:</strong> ' + cases.size() + '</p>';
        body += '<p>Este e-mail foi gerado automaticamente pelo sistema de monitoramento de SLA.</p>';
        body += '</body></html>';
        
        return body;
    }
    
    // Formatar tempo de atraso
    private String formatDelay(Long delayMinutes) {
        if (delayMinutes < 60) {
            return delayMinutes + ' minutos';
        } else {
            Long hours = delayMinutes / 60;
            Long remainingMinutes = delayMinutes - (hours * 60);
            return hours + 'h ' + remainingMinutes + 'min';
        }
    }
}