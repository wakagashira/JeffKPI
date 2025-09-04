import { LightningElement, track } from 'lwc';
import getFilterOptions from '@salesforce/apex/JeffKPIController.getFilterOptions';
import getKPIs from '@salesforce/apex/JeffKPIController.getKPIs';

export default class JeffKpi extends LightningElement {
    @track timeframe = 'MTD';
    @track ownerId = null;
    @track topN = 10;

    @track timeframeOptions = [];
    @track ownerOptions = [];
    @track rows = [];

    columns = [
        { label: 'Owner', fieldName: 'userName', type: 'text' },
        { label: 'Open Pipeline', fieldName: 'pipeline', type: 'currency' },
        { label: 'Open Count', fieldName: 'openCount', type: 'number' },
        { label: 'Won Amount', fieldName: 'wonAmount', type: 'currency' },
        { label: 'Won Count', fieldName: 'wonCount', type: 'number' }
    ];

    connectedCallback() {
        this.loadFilters();
    }

    loadFilters() {
        getFilterOptions()
            .then(res => {
                this.timeframeOptions = res.timeframeOptions?.map(o => ({ label: o.label, value: o.value })) || [];
                const owners = res.ownerOptions?.map(o => ({ label: o.label, value: o.value })) || [];
                this.ownerOptions = [{ label: 'All Owners', value: null }, ...owners];
                this.refresh();
            })
            .catch(err => {
                // eslint-disable-next-line no-console
                console.error('Filter load error', err);
                this.refresh();
            });
    }

    refresh = () => {
        getKPIs({ timeframe: this.timeframe, ownerId: this.ownerId, topN: this.topN })
            .then(data => {
                this.rows = data || [];
            })
            .catch(err => {
                // eslint-disable-next-line no-console
                console.error('KPI load error', err);
                this.rows = [];
            });
    }

    handleTimeframe = (e) => {
        this.timeframe = e.detail.value;
        this.refresh();
    }

    handleOwner = (e) => {
        const val = e.detail.value;
        this.ownerId = (val === 'null' || val === '') ? null : val;
        this.refresh();
    }

    handleTopN = (e) => {
        let n = parseInt(e.detail.value, 10);
        if (!n || n < 1) n = 10;
        this.topN = n;
        this.refresh();
    }
}
