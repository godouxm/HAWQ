drop external table esx_kernellog_je01vp03avs10_tb;
drop table esx_kernellog_je01vp03avs10err_tb;
drop table esx_kernellog_je01vp03avs10err_bytime_tb;

create external table esx_kernellog_je01vp03avs10_tb (line text) location ('pxf://localhost:50070/data/ps_datalake/performance/SP/IDCF/20150331_ESXi/esx-je01v-p03avs10.shamrock.local-2015-03-31--04.03/vmkernel.log?Profile=HdfsTextMulti') FORMAT 'TEXT' SEGMENT REJECT LIMIT 1000;
create table esx_kernellog_je01vp03avs10err_tb (daytime timestamp,err_cat text, detail text) distributed randomly;

insert into esx_kernellog_je01vp03avs10err_tb select to_timestamp(substring(line,E'\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}'),'YYYY-MM-DD HH24:MI:SS') ,regexp_replace(substring(substr(line,25),E'\\).+?:.+?:'),E'\\)',''),substr(line,0,50) from esx_kernellog_je01vp03avs10_tb where line ~*'error' or line ~*'fail';
select err_cat, count(*) from esx_kernellog_je01vp03avs10err_tb group by err_cat order by count(*) desc;

create table esx_kernellog_je01vp03avs10err_bytime_tb (daytime timestamp, err_cat text, err_count int) distributed randomly;
insert into esx_kernellog_je01vp03avs10err_bytime_tb with tmp as (select err_cat as err_cat ,extract('year' from daytime)||'/'||extract('doy' from daytime) || ' ' || extract('hour' from daytime) || ':' || trunc(extract('minute' from daytime)/10 )*10 as daytime from esx_kernellog_je01vp03avs10err_tb ) select to_timestamp(daytime,'YYYY/DDD HH24:MI'), err_cat, count(*) from tmp group by daytime, err_cat order by daytime;

select daytime, sum(case err_cat when 'ScsiDeviceIO: 2338:' then err_count end) as ScsiDeviceIO2338, sum(case err_cat when 'NMP: nmp_ThrottleLogForDevice:' then err_count end) as nmp_ThrottleLogForDevice, sum(case err_cat when 'ScsiDeviceIO: 2325:' then err_count end)as ScsiDeviceIO2325,sum(case err_cat when 'ScsiDeviceIO: 2307:' then err_count end) as ScsiDeviceIO2307 from esx_kernellog_je01vp03avs10err_bytime_tb group by daytime order by daytime;
