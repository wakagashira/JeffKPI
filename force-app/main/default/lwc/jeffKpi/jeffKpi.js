import { LightningElement, track } from 'lwc';
import getFilterOptions from '@salesforce/apex/JeffKPIController.getFilterOptions';
import getKPIs from '@salesforce/apex/JeffKPIController.getKPIs';

export default class JeffKpi extends LightningElement {
  @track timeframe='MTD'; @track ownerId=null; @track partner=null; @track topN=10;
  @track timeframeOptions=[]; @track ownerOptions=[]; @track partnerOptions=[]; @track rows=[];

  connectedCallback(){ this.loadFilters(); }
  loadFilters(){ getFilterOptions().then(res=>{ this.timeframeOptions=res.timeframeOptions||[];
    this.ownerOptions=[{label:'All Owners',value:null},...(res.ownerOptions||[])];
    this.partnerOptions=[{label:'All Partners',value:null},...(res.partnerOptions||[])];
    this.refresh(); }); }

  refresh(){ getKPIs({timeframe:this.timeframe,ownerId:this.ownerId,partner:this.partner,topN:this.topN}).then(data=>{
    this.rows = (data||[]).map(u=>({...u,
      overdueClass: (u.overdueCount>0?'slds-text-color_error':''),
      winRateClass: (u.winRate<50?'slds-text-color_error':(u.winRate>70?'slds-text-color_success':''))}));
  }); }
}