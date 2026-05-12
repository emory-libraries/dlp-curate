// datatables.net-bs4@2.3.8 downloaded from https://ga.jspm.io/npm:datatables.net-bs4@2.3.8/js/dataTables.bootstrap4.mjs

import e from"jquery";import t from"datatables.net";export{default}from"datatables.net";
/*! DataTables Bootstrap 4 integration
* © SpryMedia Ltd - datatables.net/license
*/
let n=e;n.extend(!0,t.defaults,{renderer:`bootstrap`}),n.extend(!0,t.ext.classes,{container:`dt-container dt-bootstrap4`,search:{input:`form-control form-control-sm`},length:{select:`custom-select custom-select-sm form-control form-control-sm`},processing:{container:`dt-processing card`},layout:{row:`row justify-content-between`,cell:`d-md-flex justify-content-between align-items-center`,tableCell:`col-12`,start:`dt-layout-start col-md-auto mr-auto`,end:`dt-layout-end col-md-auto ml-auto`,full:`dt-layout-full col-md`}}),t.ext.renderer.pagingButton.bootstrap=function(e,t,r,i,a){var o=[`dt-paging-button`,`page-item`];i&&o.push(`active`),a&&o.push(`disabled`);var s=n(`<li>`).addClass(o.join(` `));return{display:s,clicker:n(`<a>`,{href:a?null:`#`,class:`page-link`}).html(r).appendTo(s)}},t.ext.renderer.pagingContainer.bootstrap=function(e,t){return n(`<ul/>`).addClass(`pagination`).append(t)};

