class Attachment < ActiveRecord::Base
  belongs_to :attachable, :polymorphic => true
  belongs_to :d_object
  belongs_to :attachment_category

  def Attachment.set_position_not_working(attachable_id)
    sql=%Q{CREATE VIEW view_dobs as
select o.filename,o.id,a.position from attachments a join d_objects o
  on(a.d_object_id=o.id) where attachable_id = #{attachable_id}
   and attachable_type='ClavisManifestation' order by o.filename;
CREATE RULE rule_attach AS ON UPDATE TO view_dobs DO INSTEAD
 UPDATE attachments SET
 position = NEW.position
 WHERE AND d_object_id = NEW.id AND attachable_type='ClavisManifestation';
CREATE SEQUENCE attach_position_seq;
UPDATE view_dobs SET position = nextval('attach_position_seq');
DROP SEQUENCE attach_position_seq;
DROP RULE rule_attach ON view_dobs;
DROP VIEW view_dobs;
select o.filename,o.id,a.position from attachments a join d_objects o
  on(a.d_object_id=o.id) where attachable_type='ClavisManifestation'
  AND attachable_id = #{attachable_id} order by a.position;}
    puts sql
  end

  def Attachment.filelist(attachments)
    att=attachments.group_by {|a| a.folder}
    res=[]
    att.keys.sort.each do |k|
      tmpres=[]
      folder = k.nil? ? '' : k.capitalize
      tmpres << folder
      a=att[k]
      atc=a.sort {|x,y| x.position<=>y.position}
      dob=[]
      atc.each do |x|
        dob << x.d_object.filename
      end
      tmpres << dob
      res << tmpres
    end
    res
  end

  def Attachment.set_position(attachable_id)
    sql=%Q{select a.* from attachments a join d_objects o
   on(a.d_object_id=o.id) where a.attachable_id=#{attachable_id} order by a.attachable_type, lower(o.filename);}
    puts sql
    pos=0
    att_type=nil
    sq=[]
    Attachment.find_by_sql(sql).each do |a|
      if att_type!=a.attachable_type
        pos=1
        att_type=a.attachable_type
      end
      x ="UPDATE attachments SET position=#{pos} WHERE attachable_type='#{a.attachable_type}' AND attachable_id=#{a.attachable_id} AND d_object_id=#{a.d_object_id};"
      puts x
      sq << x
      pos+=1
    end
    Attachment.connection.execute("BEGIN;#{sq.join("\n")};COMMIT;")
  end
end
