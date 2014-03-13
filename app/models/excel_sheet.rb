class ExcelSheet < ActiveRecord::Base
  belongs_to :excel_file
  has_many :excel_cells, order: 'cell_row,cell_column'

  def columns
    sql=%Q{select cell_content as cc from public.excel_cells where excel_sheet_id = #{self.id} and cell_row=1}
    self.connection.execute(sql).collect {|r| r['cc']}
  end
  def to_label
    "#{self.excel_file.basename}(#{self.excel_file.id}) => #{self.sheet_name} (#{self.id})"
  end

  def save_views(views)
    return nil if views.nil?
    vs=[]
    views.each do |v|
      next if v.first!=self.sheet_number
      v.shift
      vs << v
    end
    vs=nil if vs.size==0
    self.views=vs
    self.save if self.changed?
  end

  def sql_views
    return [] if self.views.nil?
    res=[]
    cnt=0
    vcnt=0
    Psych.load(self.views).each do |v|
      viewdef=[]
      view_name,view_data=v
      vcnt+=1
      sqlview_name=%Q{excel_files_views."view_#{self.id}_#{vcnt}_#{view_name.downcase.gsub(' ','_')}"}
      fields=['t1.id','t1.cell_row']
      view_data.each do |d|
        fields << %Q{"#{d.first}"}
      end
      joins=[]
      cnt=0
      view_data.each do |d|
        cnt+=1
        if cnt==1
          using = ''
          columns = 'id,'
        else
          using =' USING(cell_row)'
          columns = ''
        end
        joins << %Q{(SELECT #{columns}cell_row,cell_content as "#{d.first}" FROM excel_cells
     WHERE excel_sheet_id = #{self.id} AND cell_column='#{d.last}') as t#{cnt}#{using}}
      end
      viewdef << joins.join("\nLEFT JOIN\n") + ";\n"
      res << [sqlview_name,fields,viewdef.join("\n")]
    end
    res
  end

  def create_views
    return nil if self.views.nil?
    res=self.sql_views.collect do |x|
      %Q{CREATE OR REPLACE VIEW #{x.first} AS\nSELECT #{self.id} AS excel_sheet_id,#{x[1].join(',')}\nFROM\n #{x.last}}
    end
    res.join("\n")
  end

  def load_data_from_view(view_number,querystring=nil)
    view_number=view_number.to_i
    x=self.sql_views[view_number-1]
    # fields=x[1].join(',').gsub("t1.",'')
    fields=x[1].join(',')
    columns = []
    x[1].each do |f|
      columns << f if (/^t1\./ =~ f).nil?
    end
    if querystring.nil?
      sql="SELECT\n#{fields}\nFROM\n#{x[0]} AS t1\nLIMIT 100;"
    else
      where=%Q{WHERE c.cell_content ~* #{self.connection.quote(querystring)}}
      sql="SELECT\n#{fields}\nFROM\n#{x[0]} AS t1 JOIN excel_cells c USING(excel_sheet_id,cell_row)\n#{where};"
    end
    puts sql
    self.connection.execute(sql)
  end
  def headings(view_number)
    self.sql_views[view_number-1][1].collect {|x| x.gsub('"','')}
  end
end
