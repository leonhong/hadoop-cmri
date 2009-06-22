/**
 * Copyright 2007 The Apache Software Foundation
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.apache.hadoop.hbase.mapred;

import java.io.IOException;

import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.io.Writable;
import org.apache.hadoop.io.WritableComparable;
import org.apache.hadoop.mapred.FileAlreadyExistsException;
import org.apache.hadoop.mapred.InvalidJobConfException;
import org.apache.hadoop.mapred.JobConf;
import org.apache.hadoop.mapred.OutputFormatBase;
import org.apache.hadoop.mapred.RecordWriter;
import org.apache.hadoop.mapred.Reporter;
import org.apache.hadoop.util.Progressable;

import org.apache.hadoop.hbase.HClient;
import org.apache.hadoop.hbase.io.KeyedData;
import org.apache.hadoop.hbase.io.KeyedDataArrayWritable;

import org.apache.log4j.Logger;

/**
 * Convert Map/Reduce output and write it to an HBase table
 */
public class TableOutputFormat extends OutputFormatBase {

  /** JobConf parameter that specifies the output table */
  public static final String OUTPUT_TABLE = "hbase.mapred.outputtable";

  static final Logger LOG = Logger.getLogger(TableOutputFormat.class.getName());

  /** constructor */
  public TableOutputFormat() {}

  /**
   * Convert Reduce output (key, value) to (HStoreKey, KeyedDataArrayWritable) 
   * and write to an HBase table
   */
  protected class TableRecordWriter implements RecordWriter {
    private HClient m_client;

    /**
     * Instantiate a TableRecordWriter with the HBase HClient for writing.
     * 
     * @param client
     */
    public TableRecordWriter(HClient client) {
      m_client = client;
    }

    /* (non-Javadoc)
     * @see org.apache.hadoop.mapred.RecordWriter#close(org.apache.hadoop.mapred.Reporter)
     */
    public void close(@SuppressWarnings("unused") Reporter reporter) {}

    /**
     * Expect key to be of type Text
     * Expect value to be of type KeyedDataArrayWritable
     *
     * @see org.apache.hadoop.mapred.RecordWriter#write(org.apache.hadoop.io.WritableComparable, org.apache.hadoop.io.Writable)
     */
    public void write(WritableComparable key, Writable value) throws IOException {
      LOG.debug("start write");
      Text tKey = (Text)key;
      KeyedDataArrayWritable tValue = (KeyedDataArrayWritable) value;
      KeyedData[] columns = tValue.get();

      // start transaction
      
      long xid = m_client.startUpdate(tKey);
      
      for(int i = 0; i < columns.length; i++) {
        KeyedData column = columns[i];
        m_client.put(xid, column.getKey().getColumn(), column.getData());
      }
      
      // end transaction
      
      m_client.commit(xid);

      LOG.debug("end write");
    }
  }
  
  /* (non-Javadoc)
   * @see org.apache.hadoop.mapred.OutputFormatBase#getRecordWriter(org.apache.hadoop.fs.FileSystem, org.apache.hadoop.mapred.JobConf, java.lang.String, org.apache.hadoop.util.Progressable)
   */
  @Override
  @SuppressWarnings("unused")
  public RecordWriter getRecordWriter(FileSystem ignored, JobConf job,
      String name, Progressable progress) throws IOException {
    
    // expecting exactly one path
    
    LOG.debug("start get writer");
    Text tableName = new Text(job.get(OUTPUT_TABLE));
    HClient client = null;
    try {
      client = new HClient(job);
      client.openTable(tableName);
    } catch(Exception e) {
      LOG.error(e);
    }
    LOG.debug("end get writer");
    return new TableRecordWriter(client);
  }

  /* (non-Javadoc)
   * @see org.apache.hadoop.mapred.OutputFormatBase#checkOutputSpecs(org.apache.hadoop.fs.FileSystem, org.apache.hadoop.mapred.JobConf)
   */
  @Override
  @SuppressWarnings("unused")
  public void checkOutputSpecs(FileSystem ignored, JobConf job)
  throws FileAlreadyExistsException, InvalidJobConfException, IOException {
    
    String tableName = job.get(OUTPUT_TABLE);
    if(tableName == null) {
      throw new IOException("Must specify table name");
    }
  }
}