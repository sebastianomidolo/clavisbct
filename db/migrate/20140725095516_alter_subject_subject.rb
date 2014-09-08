class AlterSubjectSubject < ActiveRecord::Migration
  def up
    add_column :subject_subject, :seq, :integer
    add_column :subject_subject, :linknote, :string, :limit=>255
    add_column :subjects, :clavis_authority_id, :integer
    add_column :subjects, :clavis_subject_class, :string, :limit=>32
    add_column :subjects, :inbct, :boolean, :default=>false
    add_column :subjects, :scope_note, :text
    # execute "ALTER TABLE public.subject_subject drop constraint subject_subject_pkey;"
    add_index :subject_subject, [:linktype,:s1_id,:s2_id], :unique=>false
    add_index :subjects, :heading
    add_index :subjects, :clavis_subject_class
    add_index :subjects, :clavis_authority_id
  end

  def down
    remove_index :subject_subject, [:linktype,:s1_id,:s2_id]
    remove_index :subjects, :heading
    remove_index :subjects, :clavis_subject_class
    remove_index :subjects, :clavis_authority_id
    remove_column :subject_subject, :seq, :linknote
    remove_column :subjects, :clavis_authority_id
    remove_column :subjects, :clavis_subject_class
    remove_column :subjects, :inbct
    remove_column :subjects, :scope_note
    # execute "ALTER TABLE public.subject_subject add primary key(linktype,s1_id,s2_id);"
  end
end
