\copy (select id,lettera,numero,o.filename from bio_iconografico_cards b join d_objects o using(id) WHERE length(lettera)=1) to '/home/storage/preesistente/bct/bio_iconografico/sql_data/cards';
\copy (select id,tags FROM bio_iconografico_topics) to '/home/storage/preesistente/bct/bio_iconografico/sql_data/topics';
\copy (select t.id as topic_id,a.d_object_id as card_id from attachments a join bio_iconografico_topics t on(t.id=a.attachable_id) JOIN bio_iconografico_cards b on(b.id=a.d_object_id) where attachable_type='BioIconograficoTopic' AND length(b.lettera)=1) to '/home/storage/preesistente/bct/bio_iconografico/sql_data/topics_cards';



