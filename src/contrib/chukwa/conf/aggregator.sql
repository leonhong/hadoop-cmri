insert into [cluster_system_metrics] (select timestamp,[avg(system_metrics)] from [system_metrics] where timestamp between '[past_hour]' and '[now]' group by timestamp);
insert into [dfs_throughput] (select timestamp,[avg(dfs_datanode)] from [dfs_datanode] where timestamp between '[past_hour]' and '[now]' group by timestamp);
insert into [cluster_disk] (select a.timestamp,a.mount,a.used,a.available,a.used_percent from (select from_unixtime(unix_timestamp(timestamp)-unix_timestamp(timestamp)%60)as timestamp,mount,avg(used) as used,avg(available) as available,avg(used_percent) as used_percent from [disk] where timestamp between '[past_hour]' and '[now]' group by timestamp,mount) as a group by a.timestamp, a.mount);
insert into [hod_job_digest] (select timestamp,d.hodid,d.userid,[avg(system_metrics)] from (select a.HodID,b.host as machine,a.userid,a.starttime,a.endtime from [HodJob] a join [hod_machine] b on (a.HodID = b.HodID) where endtime between '[past_hour]' and '[now]') as d,[system_metrics] where timestamp between d.starttime and d.endtime and host=d.machine group by hodid,timestamp);
insert into [cluster_hadoop_rpc] (select timestamp,[avg(hadoop_rpc)] from [hadoop_rpc] where timestamp between '[past_hour]' and '[now]' group by timestamp);
#insert into [cluster_hadoop_mapred] (select timestamp,[avg(hadoop_mapred_job)] from [hadoop_mapred_job] where timestamp between '[past_hour]' and '[now]' group by timestamp);
insert into [user_util] (select timestamp, j.UserID as user, sum(j.NumOfMachines) as node_total, sum(cpu_idle_pcnt*j.NumOfMachines) as cpu_unused, sum((cpu_user_pcnt+cpu_system_pcnt)*j.NumOfMachines) as cpu_used, avg(cpu_user_pcnt+cpu_system_pcnt) as cpu_used_pcnt, sum((100-(sda_busy_pcnt+sdb_busy_pcnt+sdc_busy_pcnt+sdd_busy_pcnt)/4)*j.NumOfMachines) as disk_unused, sum(((sda_busy_pcnt+sdb_busy_pcnt+sdc_busy_pcnt+sdd_busy_pcnt)/4)*j.NumOfMachines) as disk_used, avg(((sda_busy_pcnt+sdb_busy_pcnt+sdc_busy_pcnt+sdd_busy_pcnt)/4)) as disk_used_pcnt, sum((100-eth0_busy_pcnt)*j.NumOfMachines) as network_unused, sum(eth0_busy_pcnt*j.NumOfMachines) as network_used, avg(eth0_busy_pcnt) as network_used_pcnt, sum((100-mem_used_pcnt)*j.NumOfMachines) as memory_unused, sum(mem_used_pcnt*j.NumOfMachines) as memory_used, avg(mem_used_pcnt) as memory_used_pcnt from [hod_job_digest] d,[HodJob] j where (d.HodID = j.HodID) and Timestamp between '[past_hour]' and '[now]' group by j.UserID);
#insert into [node_util] select starttime, avg(unused) as unused, avg(used) as used from (select DATE_FORMAT(m.LAUNCH_TIME,'%Y-%m-%d %H:%i:%s') as starttime,sum(AvgCPUBusy*j.NumOfMachines/(60*100)) as unused,sum((100-AvgCPUBusy)*j.NumOfMachines/(60*100)) as used from HodJobDigest d join HodJob j on (d.HodID = j.HodID) join MRJob m on (m.HodID = j.HodID) where m.LAUNCH_TIME >= '2008-09-12 21:11' and m.LAUNCH_TIME <= '2008-09-12 22:11' and d.Timestamp >= m.LAUNCH_TIME and d.Timestamp <= m.FINISH_TIME group by m.MRJobID order by m.LAUNCH_TIME) as t group by t.starttime 
#insert into [jobtype_util] select CASE WHEN MRJobName like 'PigLatin%' THEN 'Pig' WHEN MRJobName like 'streamjob%' THEN 'Streaming' WHEN MRJobName like '%abacus%' THEN 'Abacus' ELSE 'Other' END as m, count(*)*j.NumOfMachines/60 as nodehours,count(distinct(MRJobID)) as jobs from HodJobDigest d join HodJob j on (d.HodID = j.HodID) join MRJob m on (m.HodID = j.HodID) where d.Timestamp >= '2008-09-12 21:11' and d.Timestamp <= '2008-09-12 22:11' and d.Timestamp >= m.LAUNCH_TIME and d.Timestamp <= m.FINISH_TIME group by CASE WHEN MRJobName like 'PigLatin%' THEN 'Pig' WHEN MRJobName like 'streamjob%' THEN 'Streaming' WHEN MRJobName like '%abacus%' THEN 'Abacus' ELSE 'Other' END order by CASE WHEN MRJobName like 'PigLatin%' THEN 'Pig' WHEN MRJobName like 'streamjob%' THEN 'Streaming' WHEN MRJobName like '%abacus%' THEN 'Abacus' ELSE 'Other' END
#insert into [a] select d.Timestamp as starttime,((AvgCPUBusy * j.NumOfMachines) / (sum(j.NumOfMachines) * 1)) as used from Digest d join HodJob j on (d.HodID = j.HodID) where d.Timestamp >= '[past_hour]' and d.Timestamp <= '[now]' group by d.Timestamp order by d.Timestamp 
#insert into [b] select m, sum(foo.nodehours) as nodehours from (select m.MRJobID, round(avg(if(AvgCPUBusy is null,0,AvgCPUBusy)),0) as m, count(*)*j.NumOfMachines/60 as nodehours from HodJobDigest d join HodJob j on (d.HodID = j.HodID) join MRJob m on (m.HodID = j.HodID) where d.Timestamp >= '[past_hour]' and d.Timestamp <= '[now]' and d.Timestamp >= m.LAUNCH_TIME and d.Timestamp <= m.FINISH_TIME group by m.MRJobID) as foo group by m; 
#insert into [c] select if(AvgCPUBusy is null,0,AvgCPUBusy) as m, CASE WHEN MRJobName like 'PigLatin%' THEN 'Pig' WHEN MRJobName like 'streamjob%' THEN 'Streaming' WHEN MRJobName like '%abacus%' THEN 'Abacus' ELSE 'Other' END as interface, count(*)*j.NumOfMachines/60 as nodehours,count(distinct(MRJobID)) as jobs from HodJobDigest d join HodJob j on (d.HodID = j.HodID) join MRJob m on (m.HodID = j.HodID) where d.Timestamp >= '[past_hour]' and d.Timestamp <= '[now]' and d.Timestamp >= m.LAUNCH_TIME and d.Timestamp <= m.FINISH_TIME group by AvgCPUBusy,CASE WHEN MRJobName like 'PigLatin%' THEN 'Pig' WHEN MRJobName like 'streamjob%' THEN 'Streaming' WHEN MRJobName like '%abacus%' THEN 'Abacus' ELSE 'Other' END order by if(AvgCPUBusy is null,0,AvgCPUBusy)