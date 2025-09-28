import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import CASE_NUMBER from '@salesforce/schema/Case.CaseNumber';
import STATUS from '@salesforce/schema/Case.Status';
import URGENCIA from '@salesforce/schema/Case.Urgencia__c';
import DEADLINE from '@salesforce/schema/Case.DataLimiteResolucao__c';

const FIELDS = [CASE_NUMBER, STATUS, URGENCIA, DEADLINE];

export default class CaseSlaWidget extends LightningElement {
  @api recordId;              
  @api flowApiName = 'CaseSLAMonitor'; 

  @track caseNumber;
  @track status;
  @track urgencia;
  deadline; // Date ISO
  timer;

  percent = 0;
  prettyRemaining = '—';
  deadlineLocal = '';
  showFlow = false;

  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
  wiredCase({ data }) {
    if (data) {
      this.caseNumber = getFieldValue(data, CASE_NUMBER);
      this.status = getFieldValue(data, STATUS);
      this.urgencia = getFieldValue(data, URGENCIA);
      this.deadline = getFieldValue(data, DEADLINE);
      this.compute(); // calcula de cara
      this.startTick();
    }
  }

  startTick() {
    clearInterval(this.timer);
    this.timer = setInterval(() => this.compute(), 1000 * 30); // a cada 30s
  }

  disconnectedCallback() {
    clearInterval(this.timer);
  }

  compute() {
    if (!this.deadline) return;

    const now = new Date();
    const end = new Date(this.deadline);
    this.deadlineLocal = end.toLocaleString();

    const totalMs = end - now;
    const overdue = totalMs <= 0;

    // porcentagem “quase real”: assume janelas de 10/20/30 min por urgência
    const bucket = this.urgencia === 'Alta' ? 10 : this.urgencia === 'Média' ? 20 : 30;
    const totalWindow = bucket * 60 * 1000;
    const clamped = Math.max(0, Math.min(totalWindow, totalMs));
    this.percent = Math.round((clamped / totalWindow) * 100);

    if (overdue) {
      this.prettyRemaining = 'SLA vencido';
      this.percent = 0;
    } else {
      const mins = Math.floor(totalMs / 60000);
      const h = Math.floor(mins / 60);
      const m = mins % 60;
      this.prettyRemaining = `${h}h ${m}m`;
    }
  }

  get ringVariant() {
    if (this.percent >= 50) return 'base-autocomplete'; // verde
    if (this.percent >= 20) return 'warning';            // âmbar
    return 'expired';                                     // vermelho
  }

  get urgencyClass() {
    return `badge ${this.urgencia === 'Alta' ? 'u-red' : this.urgencia === 'Média' ? 'u-amber' : 'u-green'}`;
  }

  get timeClass() {
    return `time ${this.percent >= 50 ? 't-green' : this.percent >= 20 ? 't-amber' : 't-red'}`;
  }

  openFlow() { this.showFlow = true; }
  closeFlow() { this.showFlow = false; }
}
