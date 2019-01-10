require 'json'
require 'csv'

# READ AND MERGE
n=0
data=[]
files=File.readlines('db/json_nationaal_archief/dir.txt')
files.each do |filename|
  json=File.read('db/json_nationaal_archief/'+filename.strip())
  d = JSON.parse(json)
  data.push(d['eadSearchResults'])
  n=n+1
end


#NORMALIZE, put everything under unitId number
data2={}
data.each do |d|
  d.each do |res|
    num=res['unitId'].split(' - ')[1]
    data2[num]=res
  end
end

#Store children under parent.
numdata={}
data2.each do |k,d|
  #puts k
  if k.split('-').count>1
    #"unitId": "2.16.5151 - 1061-1066",
    first=k.split('-')[0].to_i
    last=k.split('-')[1].to_i
    numtitle=d['unitTitle']
    numdata[numtitle]={}
    (first..last).each do |i|
      sheet_data=data2[i.to_s]
      if sheet_data.nil?
        puts i
      else
        numdata[numtitle][sheet_data['unitTitle']]=sheet_data
      end
    end
  end
end

numdata.each do |k,v|
  v.each do |k2,v|
    puts k+'..'+k2
  end
end

#Now we can store the data flattened
CSV.open("db/nationaal_archief_waterstaatskaarten_#{Date.today}.csv", "w", headers: ['unitTitle (parent)','unitTitle','unitDate','unitId','id'], write_headers: true) do |csv|
  numdata.each do |k,v|
    v.each do |k2,v2|
      puts k+'..'+k2
      csv << [k,k2,v2['unitDate'],v2['unitId'],v2['id']]
    end
  end
end