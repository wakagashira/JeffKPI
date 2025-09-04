import { LightningElement, track } from 'lwc';
import getKPIs from '@salesforce/apex/JeffKPIController.getKPIs';

export default class JeffKpi extends LightningElement {
    @track kpis = [];
    errorMessage;
    startDateStr;
    endDateStr;

    connectedCallback() {
        const today = new Date();
        const start = new Date();
        start.setDate(today.getDate() - 90);
        this.startDateStr = start.toISOString().slice(0,10);
        this.endDateStr = today.toISOString().slice(0,10);
        this.refresh();
    }

    handleStart(e) { this.startDateStr = e.target.value; }
    handleEnd(e) { this.endDateStr = e.target.value; }

    refresh() {
        this.errorMessage = undefined;
        getKPIs({
            startDate: this.startDateStr,
            endDate: this.endDateStr,
            userId: null
        })
        .then((res) => {
            this.kpis = (res || []).map(r => {
                const overdueClass = r.overdueOpps > 0 ? 'value danger' : 'value';
                let winRateClass = 'value';
                if (r.winRate < 50) {
                    winRateClass = 'value danger';
                } else if (r.winRate >= 70) {
                    winRateClass = 'value success';
                }
                return { ...r, overdueClass, winRateClass };
            });
        })
        .catch((err) => {
            try {
                this.errorMessage = err?.body?.message || err?.message || 'Unknown error';
            } catch(e) {
                this.errorMessage = 'Unknown error';
            }
        });
    }
}
