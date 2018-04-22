CLASS zcl_abapgit_ecatt_val_obj_upl DEFINITION
  PUBLIC
  INHERITING FROM cl_apl_ecatt_upload
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS:
      z_set_stream_for_upload
        IMPORTING
          im_xml TYPE xstring,

      upload REDEFINITION.

  PROTECTED SECTION.
    METHODS:
      upload_data_from_stream REDEFINITION,

      get_business_msgs_from_dom
        RAISING
          cx_ecatt_apl,

      get_impl_detail_from_dom
        RAISING
          cx_ecatt_apl,

      get_vo_flags_from_dom
        RAISING
          cx_ecatt_apl.

  PRIVATE SECTION.
    DATA: mv_external_xml TYPE xstring.

ENDCLASS.



CLASS zcl_abapgit_ecatt_val_obj_upl IMPLEMENTATION.


  METHOD get_business_msgs_from_dom.

    " downport from CL_APL_ECATT_VO_UPLOAD

    DATA: li_section            TYPE REF TO if_ixml_element,
          lt_buss_msg_ref       TYPE etvo_bus_msg_tabtype,
          lv_exception_occurred TYPE etonoff.

    li_section = template_over_all->find_from_name_ns( 'ETVO_MSG' ).

    IF NOT li_section IS INITIAL.
      CALL FUNCTION 'SDIXML_DOM_TO_DATA'
        EXPORTING
          data_as_dom    = li_section
        IMPORTING
          dataobject     = lt_buss_msg_ref
        EXCEPTIONS
          illegal_object = 1
          OTHERS         = 2.
      IF sy-subrc <> 0.
        CLEAR lt_buss_msg_ref.
      ENDIF.
    ENDIF.


    TRY.
        ecatt_vo->set_bussiness_msg( im_buss_msg_ref = lt_buss_msg_ref ).
      CATCH cx_ecatt_apl INTO exception_to_raise.
        lv_exception_occurred = 'X'.
    ENDTRY.

    IF  lv_exception_occurred = 'X'.
      raise_upload_exception( previous = exception_to_raise ).
    ENDIF.

  ENDMETHOD.


  METHOD get_impl_detail_from_dom.

    " downport from CL_APL_ECATT_VO_UPLOAD

    DATA: li_section            TYPE REF TO if_ixml_element,
          ls_impl_details       TYPE etvoimpl_det,
          lv_exception_occurred TYPE etonoff.

    li_section = template_over_all->find_from_name_ns( name = 'IMPL_DET' ).

    IF NOT li_section IS INITIAL.
      CALL FUNCTION 'SDIXML_DOM_TO_DATA'
        EXPORTING
          data_as_dom    = li_section
        IMPORTING
          dataobject     = ls_impl_details
        EXCEPTIONS
          illegal_object = 1
          OTHERS         = 2.
      IF sy-subrc <> 0.
        CLEAR ls_impl_details.
      ENDIF.
    ENDIF.


    TRY.
        ecatt_vo->set_impl_details( im_impl_details = ls_impl_details ).
      CATCH cx_ecatt_apl INTO exception_to_raise.
        lv_exception_occurred = 'X'.
    ENDTRY.

    IF  lv_exception_occurred = 'X'.
      raise_upload_exception( previous = exception_to_raise ).
    ENDIF.

  ENDMETHOD.


  METHOD get_vo_flags_from_dom.

    " downport from CL_APL_ECATT_VO_UPLOAD

    DATA: li_section            TYPE REF TO if_ixml_element,
          lv_error_prio         TYPE etvo_error_prio,
          lv_invert_validation  TYPE etvo_invert_validation,
          lv_exception_occurred TYPE etonoff.

    li_section = template_over_all->find_from_name_ns(
              name = 'INVERT_VALIDATION' ).

    IF NOT li_section IS INITIAL.
      CALL FUNCTION 'SDIXML_DOM_TO_DATA'
        EXPORTING
          data_as_dom    = li_section
        IMPORTING
          dataobject     = lv_invert_validation
        EXCEPTIONS
          illegal_object = 1
          OTHERS         = 2.
      IF sy-subrc <> 0.
        CLEAR lv_invert_validation .
      ENDIF.
    ENDIF.


    TRY.
        ecatt_vo->set_invert_validation_flag(
                    im_invert_validation = lv_invert_validation ).

      CATCH cx_ecatt_apl INTO exception_to_raise.
        lv_exception_occurred = 'X'.
    ENDTRY.

    li_section = template_over_all->find_from_name_ns(
                   name = 'ERROR_PRIORITY' ).

    IF NOT li_section IS INITIAL.
      CALL FUNCTION 'SDIXML_DOM_TO_DATA'
        EXPORTING
          data_as_dom    = li_section
        IMPORTING
          dataobject     = lv_error_prio
        EXCEPTIONS
          illegal_object = 1
          OTHERS         = 2.
      IF sy-subrc <> 0.
        CLEAR lv_invert_validation .
      ENDIF.
    ENDIF.

    TRY.
        ecatt_vo->set_error_priority(
                    im_error_prio =  lv_error_prio ).
      CATCH cx_ecatt_apl INTO exception_to_raise.
        lv_exception_occurred = 'X'.
    ENDTRY.

    IF  lv_exception_occurred = 'X'.
      raise_upload_exception( previous = exception_to_raise ).
    ENDIF.

  ENDMETHOD.


  METHOD upload.

    " We inherit from CL_APL_ECATT_UPLOAD because CL_APL_ECATT_VO_UPLOAD
    " doesn't exist in 702

    " downport from CL_APL_ECATT_VO_UPLOAD

    "26.03.2013

    DATA: ex        TYPE REF TO cx_ecatt_apl,
          l_exists  TYPE etonoff,
          l_exc_occ TYPE etonoff,
          ls_tadir  TYPE tadir.

    TRY.
        ch_object-i_devclass = ch_object-d_devclass.
        ch_object-i_akh      = ch_object-d_akh.

        super->upload(
          EXPORTING
            i_use_cts_api_2 = i_use_cts_api_2
          CHANGING
            ch_object       = ch_object ).

        upload_data_from_stream( im_xml_file = ch_object-filename ).
      CATCH cx_ecatt_apl INTO ex.
        IF template_over_all IS INITIAL.
          RAISE EXCEPTION ex.
        ELSE.
          l_exc_occ = 'X'.
        ENDIF.
    ENDTRY.

    TRY.
        get_attributes_from_dom_new( CHANGING ch_object = ch_object ).
      CATCH cx_ecatt_apl INTO ex.
        l_exc_occ = 'X'.
    ENDTRY.

    ecatt_vo ?= ecatt_object.

    TRY.
        get_impl_detail_from_dom( ).
      CATCH cx_ecatt_apl INTO ex.
        l_exc_occ = 'X'.
    ENDTRY.

    TRY.
        get_vo_flags_from_dom( ).
      CATCH cx_ecatt_apl INTO ex.
        l_exc_occ = 'X'.
    ENDTRY.

    TRY.
        get_business_msgs_from_dom( ).
      CATCH cx_ecatt_apl INTO ex.
        l_exc_occ = 'X'.
    ENDTRY.


    TRY.
        get_params_from_dom_new( im_params = ecatt_vo->params ).
      CATCH cx_ecatt_apl INTO ex.
        l_exc_occ = 'X'.
    ENDTRY.

    TRY.
        get_variants_from_dom( ecatt_vo->params ).
      CATCH cx_ecatt_apl INTO ex.
        l_exc_occ = 'X'.
    ENDTRY.

    TRY.
        l_exists = cl_apl_ecatt_object=>existence_check_object(
                im_name               = ch_object-d_obj_name
                im_version            = ch_object-d_obj_ver
                im_obj_type           = ch_object-s_obj_type
                im_exists_any_version = 'X' ).

        IF l_exists EQ space.
          ecatt_vo->set_tadir_for_new_object( im_tadir_for_new_object = tadir_preset ).
        ENDIF.
      CATCH cx_ecatt.
        CLEAR l_exists.
    ENDTRY.

    TRY.
        ecatt_vo->save( im_do_commit = 'X' ).
      CATCH cx_ecatt_apl INTO ex.
        l_exc_occ = 'X'.
    ENDTRY.

*     get devclass from existing object
    TRY.
        cl_apl_ecatt_object=>get_tadir_entry(
          EXPORTING im_obj_name = ch_object-d_obj_name
                    im_obj_type = ch_object-s_obj_type
          IMPORTING ex_tadir = ls_tadir ).

        ch_object-d_devclass = ls_tadir-devclass.

      CATCH cx_ecatt.
        CLEAR ls_tadir.
    ENDTRY.
    IF l_exc_occ = 'X'.
      raise_upload_exception( previous = ex ).
    ENDIF.

  ENDMETHOD.


  METHOD upload_data_from_stream.

    " Downport
    template_over_all = zcl_abapgit_ecatt_helper=>upload_data_from_stream( mv_external_xml ).

  ENDMETHOD.


  METHOD z_set_stream_for_upload.

    " downport from CL_ABAPGIT_ECATT_DATA_UPLOAD SET_STREAM_FOR_UPLOAD
    mv_external_xml = im_xml.

  ENDMETHOD.
ENDCLASS.