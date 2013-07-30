--A simple exec method, returning 0 on success and 1 on error.
--Inspired by WIKI_EXEC_NO_ERROR
create procedure DB.DBA.RSINE_EXEC (in text varchar)
{
  log_enable(1);
  declare exit handler for sqlstate  '*' {
    rollback work;
    return 1;
  };
  exec (text);
  commit work;
  return 0;
}
;
--Procedure to create rsine's settings table and insert default values-
create procedure DB.DBA.RSINE_CREATE_SETTINGS ()
{
declare ret int;

ret := DB.DBA.RSINE_EXEC (
'create table DB.DBA.RSINESETTINGS (
    id   integer not null,
    paramName   varchar not null,
    paramValue  varchar not null,
    primary key (id)
)')
;
dbg_printf('table created');
DB.DBA.RSINE_EXEC ( 'INSERT INTO DB.DBA.RSINESETTINGS VALUES (0, \'host\',\'http://localhost\')' );
DB.DBA.RSINE_EXEC ( 'INSERT INTO DB.DBA.RSINESETTINGS VALUES (1, \'port\',\'8080\')' );
}
;

--Above procedure is called from here, so below triggers and procedures do not fail, because
--of missing settings-table
DB.DBA.RSINE_CREATE_SETTINGS();

--Format http params for notification service
create procedure DB.DBA.TO_NOTIFICATION_FORMAT( in changeType varchar, in s any, in p any, in o any ) 
{
declare subject, predicate, object varchar;
 subject :=  '<' || id_to_iri(s) || '>';
 predicate :=  '<' || id_to_iri(p) || '>';

 IF (isiri_id (o))
 {
    object := '<' || id_to_iri(o) || '>';
 } 
 ELSE IF (is_rdf_box(o))
 {
   declare res varchar;
   declare dat, typ any;
   dat := __rdf_sqlval_of_obj (o, 1);
   typ := rdf_box_type (o);
   IF (not isstring (dat)) 
   {
    dbg_printf('NOT IS STRING');
   } 
   ELSE IF (257 <> typ)
   {
     res := coalesce ((select RDT_QNAME from DB.DBA.RDF_DATATYPE where RDT_TWOBYTE = typ));
     object := '"' || dat || '"^^' || res;
   }
   ELSE IF (257 <> rdf_box_lang (o))
   {
     res := coalesce ((select lower (RL_ID) from DB.DBA.RDF_LANGUAGE where RL_TWOBYTE = rdf_box_lang (o)));
     object := '"' || dat || '"@' || res;
   }
   ELSE 
   {
     object := '"' || dat || '"';
   }
 }

   declare params varchar;
   params := sprintf('changeType=%S\naffectedTriple=%S %S %S .', changeType, subject, predicate, object);
   return params;
}
;

--Procedure to call notification service of given changeType.
--@param changeType (according to notification service : oneof(add, remove, update).
--@param s subject of rdf triple retrieved from trigger
--@param p predicate of rdf triple retrieved from trigger
--@param o object of rdf triple retrieved from trigger
create procedure DB.DBA.RSINE_NOTIFY( in changeType varchar, in s any, in p any, in o any )
{
 declare header any;
 declare params varchar;
 declare response varchar;
 declare host varchar;
 declare port varchar;
 host := (select paramValue from DB.DBA.RSINESETTINGS where id = 0);
 port := (select paramValue from DB.DBA.RSINESETTINGS where id = 1);
 params := DB.DBA.TO_NOTIFICATION_FORMAT(changeType, s, p, o);
 response := http_get (sprintf('%s:%s',host,port), header, 'POST', 'Content-Type: text/plain', (params));
}
;

--trigger before insert calling above procedure.
create trigger RSineAddTrigger before insert on DB.DBA.RDF_QUAD referencing new as N 
{
 set triggers off;
 DB.DBA.RSINE_NOTIFY('add', N.S, N.P, N.O);
}
;

--trigger after delete calling above procedure.
create trigger RSineRemoveTrigger after delete on DB.DBA.RDF_QUAD referencing old as O
{
 set triggers off;
 DB.DBA.RSINE_NOTIFY('remove', O.S, O.P, O.O);
}
;

--defining a url to display settings (as of now : host, port).
DB.DBA.VHOST_DEFINE(is_dav=>1, lpath=>'/rsine/settings/', ppath=>'/DAV/VAD/rsine/settings.vspx', vsp_user=>'dba', opts=>vector('executable','yes'));

