class CreateBibSections < ActiveRecord::Migration
  def up
    create_table :bib_sections do |t|
      t.string :name, :limit=>32
    end
    execute %Q{
       create unique index bib_sections_name_idx on bib_sections (name);
       insert into bib_sections (name) (select distinct piano from schema_collocazioni_centrale order by piano);
       alter table schema_collocazioni_centrale add column bib_section_id integer
            references bib_sections on update cascade on delete cascade;
       alter table schema_collocazioni_centrale add column notes varchar(128);
       update schema_collocazioni_centrale cc set bib_section_id=bs.id from bib_sections bs where bs.name=cc.piano;
       alter table schema_collocazioni_centrale alter column bib_section_id set not null;
    }
  end
  def down
    execute %Q{
       alter table schema_collocazioni_centrale drop column bib_section_id;
       alter table schema_collocazioni_centrale drop column notes;
    }
    drop_table :bib_sections
  end
end
