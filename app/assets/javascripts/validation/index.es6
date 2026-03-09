import $ from 'jquery';
import { parse } from "edtf";
import 'jquery-validation';

let error_string = "Please specify the correct date range"

$.validator.addMethod("edtf_p", (value, element) => {
      try {
          let edtf2 = parse(value, { types: ['Date', 'Interval'] })
          let edtf_parser = true
          return this.optional(element) || edtf_parser;

        } catch (error) {
          let edtf_parser = false
          return this.optional(element) || edtf_parser;
        }
}, error_string);

$(document).ready(() => {
    $("form[data-param-key='curate_generic_work']").validate({
    	errorPlacement: (label, element) => {
            label.addClass('error-validate');
            label.insertAfter(element);
        },
        wrapper: 'div',
        success: (label,element) => {
            label.parent().removeClass('error-validate');
            label.parent().remove();
        }
    });

    $("#curate_generic_work_date_created").rules("add", { edtf_p: true, messages: { edtf_p: error_string}});
    $("#curate_generic_work_date_issued").rules("add", { edtf_p: true, messages: { edtf_p: error_string}});
    $("#curate_generic_work_conference_dates").rules("add", { edtf_p: true, messages: { edtf_p: error_string}});
    $("#curate_generic_work_data_collection_dates").rules("add", { edtf_p: true, messages: { edtf_p: error_string}});
    $("#curate_generic_work_copyright_date").rules("add", { edtf_p: true, messages: { edtf_p: error_string}});
    $("#curate_generic_work_scheduled_rights_review").rules("add", { edtf_p: true, messages: { edtf_p: error_string}});
    $("#curate_generic_work_date_digitized").rules("add", { edtf_p: true, messages: { edtf_p: error_string}});
});
