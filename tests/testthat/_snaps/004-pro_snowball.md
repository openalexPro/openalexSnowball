# pro_snowball result has nodes and edges

    Code
      names(results_pro)
    Output
      [1] "nodes" "edges"

# pro_snowball nodes have expected shape

    Code
      nrow(results_pro$nodes)
    Output
      [1] 46
    Code
      sort(names(results_pro$nodes))
    Output
       [1] "abstract"                       "abstract_inverted_index"       
       [3] "apc_list"                       "apc_paid"                      
       [5] "authorships"                    "awards"                        
       [7] "best_oa_location"               "biblio"                        
       [9] "citation"                       "citation_normalized_percentile"
      [11] "cited_by_count"                 "cited_by_percentile_year"      
      [13] "concepts"                       "content_urls"                  
      [15] "corresponding_author_ids"       "corresponding_institution_ids" 
      [17] "countries_distinct_count"       "counts_by_year"                
      [19] "created_date"                   "display_name"                  
      [21] "doi"                            "funders"                       
      [23] "fwci"                           "has_content"                   
      [25] "has_fulltext"                   "id"                            
      [27] "ids"                            "indexed_in"                    
      [29] "institutions"                   "institutions_distinct_count"   
      [31] "is_cited"                       "is_citing"                     
      [33] "is_keypaper"                    "is_paratext"                   
      [35] "is_retracted"                   "is_xpac"                       
      [37] "keywords"                       "language"                      
      [39] "locations"                      "locations_count"               
      [41] "mesh"                           "oa_input"                      
      [43] "open_access"                    "page"                          
      [45] "primary_location"               "primary_topic"                 
      [47] "publication_date"               "publication_year"              
      [49] "referenced_works"               "referenced_works_count"        
      [51] "related_works"                  "relation"                      
      [53] "sustainable_development_goals"  "title"                         
      [55] "topics"                         "type"                          
      [57] "updated_date"                  

# pro_snowball edges have expected shape

    Code
      nrow(results_pro$edges)
    Output
      [1] 45
    Code
      sort(names(results_pro$edges))
    Output
      [1] "edge_type" "from"      "to"       

# read_snowball with edge_type = 'core'

    Code
      snap_snowball(edge_type = "core")
    Output
      $n_nodes
      [1] 46
      
      $n_edges
      [1] 45
      
      $node_cols
       [1] "abstract"                       "abstract_inverted_index"       
       [3] "apc_list"                       "apc_paid"                      
       [5] "authorships"                    "awards"                        
       [7] "best_oa_location"               "biblio"                        
       [9] "citation"                       "citation_normalized_percentile"
      [11] "cited_by_count"                 "cited_by_percentile_year"      
      [13] "concepts"                       "content_urls"                  
      [15] "corresponding_author_ids"       "corresponding_institution_ids" 
      [17] "countries_distinct_count"       "counts_by_year"                
      [19] "created_date"                   "display_name"                  
      [21] "doi"                            "funders"                       
      [23] "fwci"                           "has_content"                   
      [25] "has_fulltext"                   "id"                            
      [27] "ids"                            "indexed_in"                    
      [29] "institutions"                   "institutions_distinct_count"   
      [31] "is_cited"                       "is_citing"                     
      [33] "is_keypaper"                    "is_paratext"                   
      [35] "is_retracted"                   "is_xpac"                       
      [37] "keywords"                       "language"                      
      [39] "locations"                      "locations_count"               
      [41] "mesh"                           "oa_input"                      
      [43] "open_access"                    "page"                          
      [45] "primary_location"               "primary_topic"                 
      [47] "publication_date"               "publication_year"              
      [49] "referenced_works"               "referenced_works_count"        
      [51] "related_works"                  "relation"                      
      [53] "sustainable_development_goals"  "title"                         
      [55] "topics"                         "type"                          
      [57] "updated_date"                  
      
      $edges
                from          to edge_type
      1  W3045921891 W1500530942      core
      2  W3045921891 W1516819724      core
      3  W3045921891 W1525595230      core
      4  W3045921891 W1572136682      core
      5  W3045921891 W1854214752      core
      6  W3045921891 W1909800943      core
      7  W3045921891  W205532704      core
      8  W3045921891 W2091406001      core
      9  W3045921891 W2096537696      core
      10 W3045921891 W2153579005      core
      11 W3045921891 W2166481425      core
      12 W3045921891 W2250539671      core
      13 W3045921891 W2251249502      core
      14 W3045921891 W2251861449      core
      15 W3045921891 W2251869843      core
      16 W3045921891 W2252212014      core
      17 W3045921891 W2442495973      core
      18 W3045921891 W2462443510      core
      19 W3045921891 W2525778437      core
      20 W3045921891 W2577479404      core
      21 W3045921891 W2593028313      core
      22 W3045921891 W2741809807      core
      23 W3045921891 W2807650837      core
      24 W3045921891 W2810053269      core
      25 W3045921891 W2849933844      core
      26 W3045921891 W2891066092      core
      27 W3045921891 W2896826974      core
      28 W3045921891 W2911997761      core
      29 W3045921891 W2936368166      core
      30 W3045921891 W2963118869      core
      31 W3045921891 W2963341956      core
      32 W3045921891  W296960487      core
      33 W3045921891  W618607536      core
      34 W3045921891   W91322025      core
      35 W3046863325 W1996515099      core
      36 W3046863325 W2741809807      core
      37 W3046863325 W2766528118      core
      38 W3046863325 W2938946739      core
      39 W3046863325 W2965202507      core
      40 W4293919086 W3046863325      core
      41 W4311043552 W3046863325      core
      42 W4387316167 W3046863325      core
      43 W4415603090 W3046863325      core
      44 W4416113766 W3046863325      core
      45 W7128689807 W3046863325      core
      

# read_snowball with edge_type = 'extended'

    Code
      snap_snowball(edge_type = "extended")
    Output
      $n_nodes
      [1] 46
      
      $n_edges
      [1] 36
      
      $node_cols
       [1] "abstract"                       "abstract_inverted_index"       
       [3] "apc_list"                       "apc_paid"                      
       [5] "authorships"                    "awards"                        
       [7] "best_oa_location"               "biblio"                        
       [9] "citation"                       "citation_normalized_percentile"
      [11] "cited_by_count"                 "cited_by_percentile_year"      
      [13] "concepts"                       "content_urls"                  
      [15] "corresponding_author_ids"       "corresponding_institution_ids" 
      [17] "countries_distinct_count"       "counts_by_year"                
      [19] "created_date"                   "display_name"                  
      [21] "doi"                            "funders"                       
      [23] "fwci"                           "has_content"                   
      [25] "has_fulltext"                   "id"                            
      [27] "ids"                            "indexed_in"                    
      [29] "institutions"                   "institutions_distinct_count"   
      [31] "is_cited"                       "is_citing"                     
      [33] "is_keypaper"                    "is_paratext"                   
      [35] "is_retracted"                   "is_xpac"                       
      [37] "keywords"                       "language"                      
      [39] "locations"                      "locations_count"               
      [41] "mesh"                           "oa_input"                      
      [43] "open_access"                    "page"                          
      [45] "primary_location"               "primary_topic"                 
      [47] "publication_date"               "publication_year"              
      [49] "referenced_works"               "referenced_works_count"        
      [51] "related_works"                  "relation"                      
      [53] "sustainable_development_goals"  "title"                         
      [55] "topics"                         "type"                          
      [57] "updated_date"                  
      
      $edges
                from          to edge_type
      1  W1516819724 W2096537696  extended
      2  W1996515099 W1572136682  extended
      3  W2096537696  W205532704  extended
      4  W2096537696 W2442495973  extended
      5  W2096537696  W618607536  extended
      6  W2250539671 W2153579005  extended
      7  W2251249502 W2153579005  extended
      8  W2251249502 W2251861449  extended
      9  W2251869843 W2251861449  extended
      10 W2252212014 W1500530942  extended
      11 W2252212014 W1525595230  extended
      12 W2252212014 W2096537696  extended
      13 W2252212014 W2442495973  extended
      14 W2252212014  W618607536  extended
      15 W2442495973  W205532704  extended
      16 W2462443510 W1500530942  extended
      17 W2462443510 W1516819724  extended
      18 W2462443510  W205532704  extended
      19 W2462443510 W2096537696  extended
      20 W2593028313 W1572136682  extended
      21 W2807650837 W2153579005  extended
      22 W2807650837 W2250539671  extended
      23 W2810053269 W1572136682  extended
      24 W2896826974 W2593028313  extended
      25 W2911997761 W2963341956  extended
      26 W2936368166 W2442495973  extended
      27 W2963341956 W2153579005  extended
      28 W2963341956 W2250539671  extended
      29 W2965202507 W2741809807  extended
      30 W4415603090 W2741809807  extended
      31 W4416113766 W2741809807  extended
      32 W7128689807 W1996515099  extended
      33 W7128689807 W2741809807  extended
      34 W7128689807 W2766528118  extended
      35 W7128689807 W2896826974  extended
      36   W91322025 W2442495973  extended
      

# read_snowball with edge_type = c('extended', 'core')

    Code
      snap_snowball(edge_type = c("extended", "core"))
    Output
      $n_nodes
      [1] 46
      
      $n_edges
      [1] 81
      
      $node_cols
       [1] "abstract"                       "abstract_inverted_index"       
       [3] "apc_list"                       "apc_paid"                      
       [5] "authorships"                    "awards"                        
       [7] "best_oa_location"               "biblio"                        
       [9] "citation"                       "citation_normalized_percentile"
      [11] "cited_by_count"                 "cited_by_percentile_year"      
      [13] "concepts"                       "content_urls"                  
      [15] "corresponding_author_ids"       "corresponding_institution_ids" 
      [17] "countries_distinct_count"       "counts_by_year"                
      [19] "created_date"                   "display_name"                  
      [21] "doi"                            "funders"                       
      [23] "fwci"                           "has_content"                   
      [25] "has_fulltext"                   "id"                            
      [27] "ids"                            "indexed_in"                    
      [29] "institutions"                   "institutions_distinct_count"   
      [31] "is_cited"                       "is_citing"                     
      [33] "is_keypaper"                    "is_paratext"                   
      [35] "is_retracted"                   "is_xpac"                       
      [37] "keywords"                       "language"                      
      [39] "locations"                      "locations_count"               
      [41] "mesh"                           "oa_input"                      
      [43] "open_access"                    "page"                          
      [45] "primary_location"               "primary_topic"                 
      [47] "publication_date"               "publication_year"              
      [49] "referenced_works"               "referenced_works_count"        
      [51] "related_works"                  "relation"                      
      [53] "sustainable_development_goals"  "title"                         
      [55] "topics"                         "type"                          
      [57] "updated_date"                  
      
      $edges
                from          to edge_type
      1  W3045921891 W1500530942      core
      2  W3045921891 W1516819724      core
      3  W3045921891 W1525595230      core
      4  W3045921891 W1572136682      core
      5  W3045921891 W1854214752      core
      6  W3045921891 W1909800943      core
      7  W3045921891  W205532704      core
      8  W3045921891 W2091406001      core
      9  W3045921891 W2096537696      core
      10 W3045921891 W2153579005      core
      11 W3045921891 W2166481425      core
      12 W3045921891 W2250539671      core
      13 W3045921891 W2251249502      core
      14 W3045921891 W2251861449      core
      15 W3045921891 W2251869843      core
      16 W3045921891 W2252212014      core
      17 W3045921891 W2442495973      core
      18 W3045921891 W2462443510      core
      19 W3045921891 W2525778437      core
      20 W3045921891 W2577479404      core
      21 W3045921891 W2593028313      core
      22 W3045921891 W2741809807      core
      23 W3045921891 W2807650837      core
      24 W3045921891 W2810053269      core
      25 W3045921891 W2849933844      core
      26 W3045921891 W2891066092      core
      27 W3045921891 W2896826974      core
      28 W3045921891 W2911997761      core
      29 W3045921891 W2936368166      core
      30 W3045921891 W2963118869      core
      31 W3045921891 W2963341956      core
      32 W3045921891  W296960487      core
      33 W3045921891  W618607536      core
      34 W3045921891   W91322025      core
      35 W3046863325 W1996515099      core
      36 W3046863325 W2741809807      core
      37 W3046863325 W2766528118      core
      38 W3046863325 W2938946739      core
      39 W3046863325 W2965202507      core
      40 W4293919086 W3046863325      core
      41 W4311043552 W3046863325      core
      42 W4387316167 W3046863325      core
      43 W4415603090 W3046863325      core
      44 W4416113766 W3046863325      core
      45 W7128689807 W3046863325      core
      46 W1516819724 W2096537696  extended
      47 W1996515099 W1572136682  extended
      48 W2096537696  W205532704  extended
      49 W2096537696 W2442495973  extended
      50 W2096537696  W618607536  extended
      51 W2250539671 W2153579005  extended
      52 W2251249502 W2153579005  extended
      53 W2251249502 W2251861449  extended
      54 W2251869843 W2251861449  extended
      55 W2252212014 W1500530942  extended
      56 W2252212014 W1525595230  extended
      57 W2252212014 W2096537696  extended
      58 W2252212014 W2442495973  extended
      59 W2252212014  W618607536  extended
      60 W2442495973  W205532704  extended
      61 W2462443510 W1500530942  extended
      62 W2462443510 W1516819724  extended
      63 W2462443510  W205532704  extended
      64 W2462443510 W2096537696  extended
      65 W2593028313 W1572136682  extended
      66 W2807650837 W2153579005  extended
      67 W2807650837 W2250539671  extended
      68 W2810053269 W1572136682  extended
      69 W2896826974 W2593028313  extended
      70 W2911997761 W2963341956  extended
      71 W2936368166 W2442495973  extended
      72 W2963341956 W2153579005  extended
      73 W2963341956 W2250539671  extended
      74 W2965202507 W2741809807  extended
      75 W4415603090 W2741809807  extended
      76 W4416113766 W2741809807  extended
      77 W7128689807 W1996515099  extended
      78 W7128689807 W2741809807  extended
      79 W7128689807 W2766528118  extended
      80 W7128689807 W2896826974  extended
      81   W91322025 W2442495973  extended
      

# read_snowball with edge_type = 'outside'

    Code
      snap_snowball(edge_type = "outside")
    Output
      $n_nodes
      [1] 46
      
      $n_edges
      [1] 1602
      
      $node_cols
       [1] "abstract"                       "abstract_inverted_index"       
       [3] "apc_list"                       "apc_paid"                      
       [5] "authorships"                    "awards"                        
       [7] "best_oa_location"               "biblio"                        
       [9] "citation"                       "citation_normalized_percentile"
      [11] "cited_by_count"                 "cited_by_percentile_year"      
      [13] "concepts"                       "content_urls"                  
      [15] "corresponding_author_ids"       "corresponding_institution_ids" 
      [17] "countries_distinct_count"       "counts_by_year"                
      [19] "created_date"                   "display_name"                  
      [21] "doi"                            "funders"                       
      [23] "fwci"                           "has_content"                   
      [25] "has_fulltext"                   "id"                            
      [27] "ids"                            "indexed_in"                    
      [29] "institutions"                   "institutions_distinct_count"   
      [31] "is_cited"                       "is_citing"                     
      [33] "is_keypaper"                    "is_paratext"                   
      [35] "is_retracted"                   "is_xpac"                       
      [37] "keywords"                       "language"                      
      [39] "locations"                      "locations_count"               
      [41] "mesh"                           "oa_input"                      
      [43] "open_access"                    "page"                          
      [45] "primary_location"               "primary_topic"                 
      [47] "publication_date"               "publication_year"              
      [49] "referenced_works"               "referenced_works_count"        
      [51] "related_works"                  "relation"                      
      [53] "sustainable_development_goals"  "title"                         
      [55] "topics"                         "type"                          
      [57] "updated_date"                  
      
      $edges
                  from          to edge_type
      1    W1500530942 W1516240602   outside
      2    W1500530942 W1975879668   outside
      3    W1500530942 W1979773093   outside
      4    W1500530942 W1982464493   outside
      5    W1500530942 W2002664886   outside
      6    W1500530942 W2006802446   outside
      7    W1500530942 W2027943492   outside
      8    W1500530942 W2050355460   outside
      9    W1500530942 W2053154970   outside
      10   W1500530942 W2070285512   outside
      11   W1500530942 W2101819947   outside
      12   W1500530942 W2120587524   outside
      13   W1500530942 W2123107826   outside
      14   W1500530942 W2146777297   outside
      15   W1500530942 W2153222072   outside
      16   W1500530942 W2402929825   outside
      17   W1500530942 W2907147533   outside
      18   W1516819724 W2479517029   outside
      19   W1516819724 W2911964244   outside
      20   W1525595230 W1907578970   outside
      21   W1525595230 W2015933299   outside
      22   W1525595230 W2064418625   outside
      23   W1525595230 W2066636486   outside
      24   W1525595230 W2138621811   outside
      25   W1525595230 W2144270295   outside
      26   W1525595230 W2150824314   outside
      27   W1525595230 W2156641871   outside
      28   W1525595230 W2169602691   outside
      29   W1525595230 W3122553793   outside
      30   W1572136682 W2003014790   outside
      31   W1572136682 W2032800154   outside
      32   W1572136682 W2091636366   outside
      33   W1572136682 W2128980381   outside
      34   W1572136682 W6929594198   outside
      35   W1572136682 W6939400475   outside
      36   W1909800943 W1579541243   outside
      37   W1909800943 W1889026943   outside
      38   W1909800943 W1964404845   outside
      39   W1909800943 W1972137089   outside
      40   W1909800943 W1989868360   outside
      41   W1909800943 W1995945562   outside
      42   W1909800943 W2016264902   outside
      43   W1909800943 W2035729615   outside
      44   W1909800943 W2065900167   outside
      45   W1909800943 W2069057356   outside
      46   W1909800943 W2085125419   outside
      47   W1909800943 W2097879961   outside
      48   W1909800943 W2121878111   outside
      49   W1909800943 W2124181495   outside
      50   W1909800943 W2155916155   outside
      51   W1909800943 W2173213060   outside
      52   W1909800943 W2291351514   outside
      53   W1909800943 W2582743722   outside
      54   W1909800943 W3026721701   outside
      55   W1909800943 W3106889297   outside
      56   W1909800943 W4210688903   outside
      57   W1909800943 W4230173782   outside
      58   W1909800943 W4298872162   outside
      59   W1909800943 W4301752816   outside
      60   W1909800943 W4399583268   outside
      61   W1909800943  W596013814   outside
      62   W1909800943  W652383646   outside
      63   W1996515099 W1553564559   outside
      64   W1996515099 W1715687586   outside
      65   W1996515099 W1970217003   outside
      66   W1996515099 W1982149803   outside
      67   W1996515099 W1983161454   outside
      68   W1996515099 W1994503791   outside
      69   W1996515099 W1997299998   outside
      70   W1996515099 W2010112142   outside
      71   W1996515099 W2027794266   outside
      72   W1996515099 W2045313021   outside
      73   W1996515099 W2048185449   outside
      74   W1996515099 W2049863276   outside
      75   W1996515099 W2062435070   outside
      76   W1996515099 W2068425785   outside
      77   W1996515099 W2068875466   outside
      78   W1996515099 W2071931474   outside
      79   W1996515099 W2073023209   outside
      80   W1996515099 W2086496065   outside
      81   W1996515099 W2104772551   outside
      82   W1996515099 W2142149702   outside
      83   W1996515099 W2148772173   outside
      84   W1996515099 W2915069347   outside
      85   W1996515099 W3099857050   outside
      86   W1996515099 W3101021061   outside
      87   W1996515099 W3101689191   outside
      88   W1996515099 W3102119685   outside
      89   W1996515099 W3105776975   outside
      90   W1996515099 W3130540911   outside
      91   W1996515099 W3154793279   outside
      92   W1996515099 W4214836368   outside
      93   W1996515099 W4240507605   outside
      94   W2091406001 W1994149163   outside
      95   W2091406001 W1994162483   outside
      96   W2091406001 W2007558434   outside
      97   W2091406001 W2018858523   outside
      98   W2091406001 W2031797820   outside
      99   W2091406001 W2032592399   outside
      100  W2091406001 W2043845271   outside
      101  W2091406001 W2058873076   outside
      102  W2091406001 W2120062331   outside
      103  W2091406001 W2168745915   outside
      104  W2091406001 W2797098714   outside
      105  W2091406001 W2960963589   outside
      106  W2096537696 W1480287196   outside
      107  W2096537696 W1515842608   outside
      108  W2096537696 W1568297139   outside
      109  W2096537696 W2001829063   outside
      110  W2096537696 W2004761926   outside
      111  W2096537696 W2006802446   outside
      112  W2096537696 W2017513070   outside
      113  W2096537696 W2028473264   outside
      114  W2096537696 W2040838629   outside
      115  W2096537696 W2050355460   outside
      116  W2096537696 W2051649768   outside
      117  W2096537696 W2053154970   outside
      118  W2096537696 W2076327529   outside
      119  W2096537696 W2083566963   outside
      120  W2096537696 W2085809930   outside
      121  W2096537696 W2101390659   outside
      122  W2096537696 W2105897558   outside
      123  W2096537696 W2107141268   outside
      124  W2096537696 W2110854897   outside
      125  W2096537696 W2115516470   outside
      126  W2096537696 W2116692665   outside
      127  W2096537696 W2118585731   outside
      128  W2096537696 W2120587524   outside
      129  W2096537696 W2121678130   outside
      130  W2096537696 W2123107826   outside
      131  W2096537696 W2143589337   outside
      132  W2096537696 W2146737815   outside
      133  W2096537696 W2153635508   outside
      134  W2096537696 W2158291389   outside
      135  W2096537696 W2159230276   outside
      136  W2096537696 W2168579166   outside
      137  W2096537696 W2168652246   outside
      138  W2096537696 W2168905447   outside
      139  W2096537696 W2171283231   outside
      140  W2096537696 W2251672315   outside
      141  W2096537696 W2402929825   outside
      142  W2096537696  W273036708   outside
      143  W2096537696 W2781804600   outside
      144  W2096537696 W2801356492   outside
      145  W2096537696 W2911864677   outside
      146  W2096537696 W2914431807   outside
      147  W2096537696 W4246948003   outside
      148  W2096537696 W4250467157   outside
      149  W2096537696 W4285719527   outside
      150  W2096537696 W6603123688   outside
      151  W2096537696 W6608395927   outside
      152  W2096537696 W6610009877   outside
      153  W2096537696 W6630735327   outside
      154  W2096537696 W6657784456   outside
      155  W2096537696 W6675247125   outside
      156  W2096537696 W6676803185   outside
      157  W2096537696 W6677293857   outside
      158  W2096537696 W6677656871   outside
      159  W2096537696 W6678430481   outside
      160  W2096537696 W6681160867   outside
      161  W2096537696 W6681296008   outside
      162  W2096537696 W6691445279   outside
      163  W2096537696 W6713316921   outside
      164  W2096537696   W76749362   outside
      165  W2153579005 W1423339008   outside
      166  W2153579005 W1498436455   outside
      167  W2153579005 W1614298861   outside
      168  W2153579005 W1662133657   outside
      169  W2153579005 W1889268436   outside
      170  W2153579005 W1965154800   outside
      171  W2153579005 W1970689298   outside
      172  W2153579005   W21006490   outside
      173  W2153579005 W2117130368   outside
      174  W2153579005 W2120861206   outside
      175  W2153579005 W2131462252   outside
      176  W2153579005 W2132339004   outside
      177  W2153579005 W2138204974   outside
      178  W2153579005 W2141599568   outside
      179  W2153579005 W2158139315   outside
      180  W2153579005 W2171928131   outside
      181  W2153579005   W22861983   outside
      182  W2153579005 W2962769333   outside
      183  W2153579005   W36903255   outside
      184  W2166481425 W1541806262   outside
      185  W2166481425 W1974165523   outside
      186  W2166481425 W1974971448   outside
      187  W2166481425 W1976738492   outside
      188  W2166481425 W1982398489   outside
      189  W2166481425 W1996732432   outside
      190  W2166481425 W2023761963   outside
      191  W2166481425 W2024013999   outside
      192  W2166481425 W2051203581   outside
      193  W2166481425 W2076022457   outside
      194  W2166481425 W2087871831   outside
      195  W2166481425 W3008021358   outside
      196  W2250539671 W1495550473   outside
      197  W2250539671 W1499253590   outside
      198  W2250539671 W1614298861   outside
      199  W2250539671 W1978400666   outside
      200  W2250539671 W1981617416   outside
      201  W2250539671 W2067438047   outside
      202  W2250539671 W2072128103   outside
      203  W2250539671 W2077428231   outside
      204  W2250539671 W2080100102   outside
      205  W2250539671 W2097732278   outside
      206  W2250539671 W2103318667   outside
      207  W2250539671 W2117130368   outside
      208  W2250539671 W2118020653   outside
      209  W2250539671 W2133280805   outside
      210  W2250539671 W2141599568   outside
      211  W2250539671 W2144578941   outside
      212  W2250539671 W2146502635   outside
      213  W2250539671 W2147152072   outside
      214  W2250539671 W2155169782   outside
      215  W2250539671 W2158139315   outside
      216  W2250539671 W2158899491   outside
      217  W2250539671 W2164019165   outside
      218  W2250539671 W2167510172   outside
      219  W2250539671 W2250189634   outside
      220  W2250539671 W2251012068   outside
      221  W2250539671 W2251803266   outside
      222  W2250539671 W4285719527   outside
      223  W2251249502  W106250223   outside
      224  W2251249502 W1614298861   outside
      225  W2251249502 W1942015218   outside
      226  W2251249502 W1977155386   outside
      227  W2251249502 W1980318031   outside
      228  W2251249502 W1982854161   outside
      229  W2251249502 W2016381774   outside
      230  W2251249502 W2072240081   outside
      231  W2251249502 W2112178080   outside
      232  W2251249502 W2138615112   outside
      233  W2251249502 W2144232471   outside
      234  W2251249502 W2145327091   outside
      235  W2251249502 W2150248423   outside
      236  W2251249502 W2153233077   outside
      237  W2251249502 W2250287365   outside
      238  W2251249502 W2250397934   outside
      239  W2251249502 W2250590686   outside
      240  W2251249502 W2251521080   outside
      241  W2251249502 W4245436919   outside
      242  W2251249502 W4294170691   outside
      243  W2251861449  W145425800   outside
      244  W2251861449 W1980776243   outside
      245  W2251861449 W2011632873   outside
      246  W2251861449 W2038721957   outside
      247  W2251861449 W2080100102   outside
      248  W2251861449 W2088911157   outside
      249  W2251861449 W2121184547   outside
      250  W2251861449 W2147192413   outside
      251  W2251861449 W2164290393   outside
      252  W2251861449 W2169279899   outside
      253  W2251869843 W1484288670   outside
      254  W2251869843 W1608322251   outside
      255  W2251869843 W1889268436   outside
      256  W2251869843 W1984052055   outside
      257  W2251869843 W2104740481   outside
      258  W2251869843 W2106612368   outside
      259  W2251869843 W2108704114   outside
      260  W2251869843 W2118296893   outside
      261  W2251869843 W2121129054   outside
      262  W2251869843 W2130158090   outside
      263  W2251869843 W2137607259   outside
      264  W2251869843 W2139404310   outside
      265  W2251869843 W2155484602   outside
      266  W2251869843 W2165646510   outside
      267  W2251869843 W2170502136   outside
      268  W2251869843 W2250307601   outside
      269  W2251869843 W2250790822   outside
      270  W2251869843 W2251145153   outside
      271  W2251869843 W2251318600   outside
      272  W2251869843 W2251919380   outside
      273  W2251869843 W2396767181   outside
      274  W2252212014  W102951417   outside
      275  W2252212014 W1570031249   outside
      276  W2252212014 W1574989980   outside
      277  W2252212014 W2032566933   outside
      278  W2252212014 W2045738181   outside
      279  W2252212014 W2101390659   outside
      280  W2252212014 W2105140343   outside
      281  W2252212014 W2118370253   outside
      282  W2252212014 W2120481102   outside
      283  W2252212014 W2120587524   outside
      284  W2252212014 W2127368645   outside
      285  W2252212014 W2128108764   outside
      286  W2252212014 W2133227439   outside
      287  W2252212014 W2144512097   outside
      288  W2252212014 W2149801561   outside
      289  W2252212014 W2158291389   outside
      290  W2252212014 W2160992478   outside
      291  W2252212014 W2166806362   outside
      292  W2252212014 W2168905447   outside
      293  W2252212014 W2171283231   outside
      294  W2252212014 W2252173290   outside
      295  W2252212014 W3101913037   outside
      296  W2252212014   W41621595   outside
      297  W2252212014 W4285719527   outside
      298  W2252212014   W76749362   outside
      299  W2442495973  W135764212   outside
      300  W2442495973 W1497212108   outside
      301  W2442495973 W1513168555   outside
      302  W2442495973 W1559838295   outside
      303  W2442495973 W1571541043   outside
      304  W2442495973 W1577877742   outside
      305  W2442495973 W1605860798   outside
      306  W2442495973 W1626945812   outside
      307  W2442495973 W1673478674   outside
      308  W2442495973 W1710422233   outside
      309  W2442495973 W1825434232   outside
      310  W2442495973 W1828401780   outside
      311  W2442495973 W1950936596   outside
      312  W2442495973 W1956559956   outside
      313  W2442495973 W1973513505   outside
      314  W2442495973 W1974339500   outside
      315  W2442495973 W1977736702   outside
      316  W2442495973 W1979068940   outside
      317  W2442495973 W1980118257   outside
      318  W2442495973 W1982110842   outside
      319  W2442495973 W1982697162   outside
      320  W2442495973 W1996250712   outside
      321  W2442495973 W2002664886   outside
      322  W2442495973 W2004737172   outside
      323  W2442495973 W2005422315   outside
      324  W2442495973 W2007709031   outside
      325  W2442495973 W2027429929   outside
      326  W2442495973 W2028009320   outside
      327  W2442495973 W2028473264   outside
      328  W2442495973 W2028651247   outside
      329  W2442495973 W2028962062   outside
      330  W2442495973 W2031275836   outside
      331  W2442495973 W2038051455   outside
      332  W2442495973 W2041950349   outside
      333  W2442495973 W2042432758   outside
      334  W2442495973 W2048207804   outside
      335  W2442495973 W2049852578   outside
      336  W2442495973 W2051419509   outside
      337  W2442495973 W2060216474   outside
      338  W2442495973 W2061312249   outside
      339  W2442495973 W2064957402   outside
      340  W2442495973 W2065553296   outside
      341  W2442495973 W2088802729   outside
      342  W2442495973 W2092246763   outside
      343  W2442495973 W2092488901   outside
      344  W2442495973 W2093506210   outside
      345  W2442495973 W2097096171   outside
      346  W2442495973 W2098618819   outside
      347  W2442495973 W2100374502   outside
      348  W2442495973 W2101390659   outside
      349  W2442495973 W2109730238   outside
      350  W2442495973 W2110017317   outside
      351  W2442495973 W2114332321   outside
      352  W2442495973 W2116780029   outside
      353  W2442495973 W2118119027   outside
      354  W2442495973 W2118733980   outside
      355  W2442495973 W2118898541   outside
      356  W2442495973 W2119187129   outside
      357  W2442495973 W2126942339   outside
      358  W2442495973 W2128970689   outside
      359  W2442495973 W2134999050   outside
      360  W2442495973 W2137591918   outside
      361  W2442495973 W2149593800   outside
      362  W2442495973 W2150569271   outside
      363  W2442495973 W2153222072   outside
      364  W2442495973 W2153804780   outside
      365  W2442495973 W2154498027   outside
      366  W2442495973 W2158291389   outside
      367  W2442495973 W2164777277   outside
      368  W2442495973 W2166347079   outside
      369  W2442495973 W2166806362   outside
      370  W2442495973 W2491155000   outside
      371  W2442495973 W2907147533   outside
      372  W2442495973 W2998461326   outside
      373  W2442495973 W3035219831   outside
      374  W2442495973 W4231162912   outside
      375  W2442495973 W4231741839   outside
      376  W2442495973 W4235728695   outside
      377  W2442495973 W4241850027   outside
      378  W2442495973   W99221312   outside
      379  W2462443510 W1523904107   outside
      380  W2462443510 W1978059262   outside
      381  W2462443510 W2023930240   outside
      382  W2462443510 W2088336913   outside
      383  W2462443510 W2123682292   outside
      384  W2462443510 W2146936057   outside
      385  W2462443510 W2149801561   outside
      386  W2462443510 W2160969793   outside
      387  W2462443510 W2250440868   outside
      388  W2462443510 W2479156095   outside
      389  W2462443510 W2517720908   outside
      390  W2462443510 W2579547421   outside
      391  W2462443510  W304411614   outside
      392  W2462443510 W4255299494   outside
      393  W2462443510   W80379025   outside
      394  W2462443510  W926830766   outside
      395  W2525778437 W1968594024   outside
      396  W2525778437 W2121879602   outside
      397  W2525778437 W2251743902   outside
      398  W2525778437 W2964121744   outside
      399  W2577479404 W1589660493   outside
      400  W2577479404 W2012251902   outside
      401  W2577479404 W2073023209   outside
      402  W2577479404 W2169082498   outside
      403  W2593028313 W1508473354   outside
      404  W2593028313 W1517593287   outside
      405  W2593028313 W1640247171   outside
      406  W2593028313 W1953503995   outside
      407  W2593028313 W1986828568   outside
      408  W2593028313 W2019753053   outside
      409  W2593028313 W2023930240   outside
      410  W2593028313 W2041971736   outside
      411  W2593028313 W2042990063   outside
      412  W2593028313 W2064816492   outside
      413  W2593028313 W2064961604   outside
      414  W2593028313 W2068452509   outside
      415  W2593028313 W2073023209   outside
      416  W2593028313 W2101234009   outside
      417  W2593028313 W2128438887   outside
      418  W2593028313 W2129286173   outside
      419  W2593028313 W2132631086   outside
      420  W2593028313 W2151568674   outside
      421  W2593028313 W2164277894   outside
      422  W2593028313 W2300777861   outside
      423  W2593028313 W2472513771   outside
      424  W2593028313 W2479682262   outside
      425  W2593028313 W2525687297   outside
      426  W2593028313 W2567946352   outside
      427  W2593028313 W2573225424   outside
      428  W2593028313 W2963475133   outside
      429  W2593028313 W3130540911   outside
      430  W2593028313 W4235451245   outside
      431  W2593028313 W4255299494   outside
      432  W2593028313 W6675354045   outside
      433  W2741809807 W1560783210   outside
      434  W2741809807 W1724212071   outside
      435  W2741809807 W1767272795   outside
      436  W2741809807 W1917633107   outside
      437  W2741809807 W1931854307   outside
      438  W2741809807 W1944943415   outside
      439  W2741809807 W1957687230   outside
      440  W2741809807 W1989318653   outside
      441  W2741809807 W2003844967   outside
      442  W2741809807 W2016860460   outside
      443  W2741809807 W2020807482   outside
      444  W2741809807 W2029057325   outside
      445  W2741809807 W2031754690   outside
      446  W2741809807 W2048185449   outside
      447  W2741809807 W2078310052   outside
      448  W2741809807 W2089123513   outside
      449  W2741809807 W2115339903   outside
      450  W2741809807 W2140880926   outside
      451  W2741809807 W2160597895   outside
      452  W2741809807 W2231201268   outside
      453  W2741809807 W2299516731   outside
      454  W2741809807 W2306268324   outside
      455  W2741809807 W2322381034   outside
      456  W2741809807 W2343014812   outside
      457  W2741809807 W2345375849   outside
      458  W2741809807 W2463568293   outside
      459  W2741809807 W2511661767   outside
      460  W2741809807 W2511663072   outside
      461  W2741809807 W2520991028   outside
      462  W2741809807 W2563251083   outside
      463  W2741809807 W2566143661   outside
      464  W2741809807 W2587705861   outside
      465  W2741809807 W2588027260   outside
      466  W2741809807 W2611818942   outside
      467  W2741809807 W2737712680   outside
      468  W2741809807 W2753353163   outside
      469  W2741809807 W2762597540   outside
      470  W2741809807 W2785823074   outside
      471  W2741809807 W2953072907   outside
      472  W2741809807 W2997143876   outside
      473  W2741809807 W3012252063   outside
      474  W2741809807 W3121567788   outside
      475  W2741809807 W4254015553   outside
      476  W2741809807 W4298108315   outside
      477  W2741809807 W4301734034   outside
      478  W2741809807 W6637734586   outside
      479  W2741809807 W6640061894   outside
      480  W2741809807 W6640335369   outside
      481  W2741809807 W6640848857   outside
      482  W2741809807 W6687877900   outside
      483  W2741809807 W6725637556   outside
      484  W2741809807 W6744027076   outside
      485  W2741809807 W6887727194   outside
      486  W2741809807 W6948399261   outside
      487  W2766528118 W1005483714   outside
      488  W2766528118 W1522052181   outside
      489  W2766528118 W1715687586   outside
      490  W2766528118 W1909753460   outside
      491  W2766528118 W2003786618   outside
      492  W2766528118 W2086496065   outside
      493  W2766528118 W2257858171   outside
      494  W2766528118 W2511663072   outside
      495  W2766528118 W2521613271   outside
      496  W2766528118 W3122411544   outside
      497  W2766528118 W4285719527   outside
      498  W2766528118 W4297173270   outside
      499  W2766528118 W6892301120   outside
      500  W2807650837  W132022748   outside
      501  W2807650837 W1513718494   outside
      502  W2807650837  W155592222   outside
      503  W2807650837 W1570098300   outside
      504  W2807650837 W1584739173   outside
      505  W2807650837 W1662133657   outside
      506  W2807650837 W1836814292   outside
      507  W2807650837 W1854884267   outside
      508  W2807650837 W1973826788   outside
      509  W2807650837 W1978400666   outside
      510  W2807650837 W1981782113   outside
      511  W2807650837 W1990858934   outside
      512  W2807650837 W2019096529   outside
      513  W2807650837 W2049684127   outside
      514  W2807650837 W2063804110   outside
      515  W2807650837 W2072644219   outside
      516  W2807650837 W2102343050   outside
      517  W2807650837 W2105286768   outside
      518  W2807650837 W2107550813   outside
      519  W2807650837 W2125031621   outside
      520  W2807650837 W2147152072   outside
      521  W2807650837 W2148763605   outside
      522  W2807650837 W2171343266   outside
      523  W2807650837 W2180877453   outside
      524  W2807650837 W2251769296   outside
      525  W2807650837 W2296560646   outside
      526  W2807650837 W2299546746   outside
      527  W2807650837 W2307020448   outside
      528  W2807650837 W2323881768   outside
      529  W2807650837 W2399378566   outside
      530  W2807650837 W2475032637   outside
      531  W2807650837 W2489258484   outside
      532  W2807650837 W2508578776   outside
      533  W2807650837  W250892164   outside
      534  W2807650837 W2515394543   outside
      535  W2807650837 W2558546935   outside
      536  W2807650837 W2605242105   outside
      537  W2807650837 W2617139001   outside
      538  W2807650837 W2735070829   outside
      539  W2807650837 W2740377422   outside
      540  W2807650837 W2741040861   outside
      541  W2807650837 W2759556264   outside
      542  W2807650837 W2767231321   outside
      543  W2807650837 W2804830075   outside
      544  W2807650837 W2904266214   outside
      545  W2807650837 W2950577311   outside
      546  W2807650837 W2963099212   outside
      547  W2807650837 W2963586458   outside
      548  W2807650837 W2963733758   outside
      549  W2807650837 W2963760040   outside
      550  W2807650837 W2963780471   outside
      551  W2807650837 W2964231305   outside
      552  W2807650837 W2964325543   outside
      553  W2807650837 W2979401726   outside
      554  W2807650837 W3101767658   outside
      555  W2807650837   W31873193   outside
      556  W2807650837   W36967578   outside
      557  W2807650837  W594069839   outside
      558  W2807650837  W650889124   outside
      559  W2807650837   W88980739   outside
      560  W2810053269 W1509146554   outside
      561  W2810053269  W160748399   outside
      562  W2810053269 W1775823180   outside
      563  W2810053269 W1793987952   outside
      564  W2810053269 W1965638471   outside
      565  W2810053269 W1974132922   outside
      566  W2810053269 W1986828568   outside
      567  W2810053269 W1992066818   outside
      568  W2810053269 W2048803507   outside
      569  W2810053269 W2051290211   outside
      570  W2810053269 W2053763640   outside
      571  W2810053269 W2073023209   outside
      572  W2810053269 W2097343308   outside
      573  W2810053269 W2110787135   outside
      574  W2810053269 W2113329865   outside
      575  W2810053269 W2115584760   outside
      576  W2810053269 W2127267264   outside
      577  W2810053269 W2127492100   outside
      578  W2810053269 W2132346968   outside
      579  W2810053269 W2164277894   outside
      580  W2810053269 W2164632072   outside
      581  W2810053269 W2170857652   outside
      582  W2810053269 W2378789977   outside
      583  W2810053269 W2396414759   outside
      584  W2810053269  W250553205   outside
      585  W2810053269 W2519262354   outside
      586  W2810053269 W2521092731   outside
      587  W2810053269 W2525691018   outside
      588  W2810053269 W2579102106   outside
      589  W2810053269 W2949377321   outside
      590  W2810053269 W2962690183   outside
      591  W2810053269 W2964135759   outside
      592  W2810053269 W4233608910   outside
      593  W2810053269 W4244063436   outside
      594  W2810053269 W4299802090   outside
      595  W2810053269  W595373256   outside
      596  W2810053269 W6621754700   outside
      597  W2810053269 W6634065055   outside
      598  W2810053269 W6637963346   outside
      599  W2810053269 W6641497203   outside
      600  W2810053269 W6665520411   outside
      601  W2810053269 W6676908494   outside
      602  W2810053269 W6677385034   outside
      603  W2810053269 W6678843822   outside
      604  W2810053269 W6678993650   outside
      605  W2810053269 W6709306182   outside
      606  W2810053269 W6711866171   outside
      607  W2810053269 W6732338472   outside
      608  W2810053269 W6791373111   outside
      609  W2810053269 W6891735641   outside
      610  W2810053269 W6903422917   outside
      611  W2810053269 W6990009642   outside
      612  W2810053269   W70125044   outside
      613  W2810053269   W76678209   outside
      614  W2849933844 W1941311111   outside
      615  W2849933844 W1979926645   outside
      616  W2849933844 W2064816492   outside
      617  W2849933844 W2073023209   outside
      618  W2849933844 W2114094964   outside
      619  W2849933844 W2127896742   outside
      620  W2849933844 W2132667083   outside
      621  W2849933844 W2164277894   outside
      622  W2849933844 W2274116681   outside
      623  W2849933844 W2338922590   outside
      624  W2849933844 W2397349251   outside
      625  W2849933844 W2488987723   outside
      626  W2849933844 W2514259213   outside
      627  W2849933844 W2518646621   outside
      628  W2849933844 W2610080780   outside
      629  W2849933844 W2728153594   outside
      630  W2849933844 W2766003986   outside
      631  W2849933844 W2766779024   outside
      632  W2849933844 W2793099400   outside
      633  W2849933844 W2804115742   outside
      634  W2849933844 W2962678849   outside
      635  W2849933844 W3100189117   outside
      636  W2849933844 W3125169599   outside
      637  W2849933844 W4233851799   outside
      638  W2849933844 W4254027920   outside
      639  W2849933844 W4412275979   outside
      640  W2849933844 W6979848335   outside
      641  W2891066092  W124349300   outside
      642  W2891066092  W147350961   outside
      643  W2891066092 W1488363850   outside
      644  W2891066092 W1495320385   outside
      645  W2891066092 W1533576359   outside
      646  W2891066092 W1556170248   outside
      647  W2891066092 W1556533847   outside
      648  W2891066092 W1568406678   outside
      649  W2891066092 W1574440611   outside
      650  W2891066092 W1579811429   outside
      651  W2891066092 W1586232984   outside
      652  W2891066092 W1588395940   outside
      653  W2891066092 W1597568827   outside
      654  W2891066092 W1927197813   outside
      655  W2891066092 W1964196470   outside
      656  W2891066092 W1972398108   outside
      657  W2891066092 W1991169218   outside
      658  W2891066092 W2068648383   outside
      659  W2891066092 W2085574295   outside
      660  W2891066092 W2097983280   outside
      661  W2891066092 W2101672700   outside
      662  W2891066092 W2131046076   outside
      663  W2891066092 W2136040516   outside
      664  W2891066092 W2148147515   outside
      665  W2891066092 W2191713413   outside
      666  W2891066092   W22416009   outside
      667  W2891066092 W2303522472   outside
      668  W2891066092 W2314309526   outside
      669  W2891066092 W2322182166   outside
      670  W2891066092 W2480659012   outside
      671  W2891066092 W2484804913   outside
      672  W2891066092 W2487063104   outside
      673  W2891066092 W2489155358   outside
      674  W2891066092 W2553936366   outside
      675  W2891066092 W2559748900   outside
      676  W2891066092 W2566705968   outside
      677  W2891066092 W2568177153   outside
      678  W2891066092 W2587890708   outside
      679  W2891066092 W2594829037   outside
      680  W2891066092 W2757396425   outside
      681  W2891066092  W376675759   outside
      682  W2891066092  W398920993   outside
      683  W2891066092 W4233028252   outside
      684  W2891066092 W4285719527   outside
      685  W2891066092  W432761262   outside
      686  W2891066092  W564018664   outside
      687  W2891066092  W582936456   outside
      688  W2891066092  W589544906   outside
      689  W2891066092  W612069518   outside
      690  W2891066092  W650398330   outside
      691  W2891066092  W658502922   outside
      692  W2891066092 W6617934947   outside
      693  W2891066092 W6619027249   outside
      694  W2891066092 W6628927097   outside
      695  W2891066092 W6630254032   outside
      696  W2891066092 W6631107811   outside
      697  W2891066092 W6640393395   outside
      698  W2891066092 W6721270291   outside
      699  W2891066092 W6722512470   outside
      700  W2891066092 W6730135315   outside
      701  W2891066092 W6731382943   outside
      702  W2891066092 W6734215390   outside
      703  W2891066092 W6744944060   outside
      704  W2891066092 W6809499650   outside
      705  W2891066092 W6881230805   outside
      706  W2891066092 W7005424199   outside
      707  W2896826974  W143675921   outside
      708  W2896826974 W1491754772   outside
      709  W2896826974 W1523932947   outside
      710  W2896826974 W1529519400   outside
      711  W2896826974 W1531607676   outside
      712  W2896826974 W1536474489   outside
      713  W2896826974 W1696956904   outside
      714  W2896826974 W1731700882   outside
      715  W2896826974 W1761052593   outside
      716  W2896826974 W1958928194   outside
      717  W2896826974 W1965259429   outside
      718  W2896826974 W1968365422   outside
      719  W2896826974 W1971087125   outside
      720  W2896826974 W1977862340   outside
      721  W2896826974 W1979116104   outside
      722  W2896826974 W1982070737   outside
      723  W2896826974 W1982826806   outside
      724  W2896826974 W1986192078   outside
      725  W2896826974 W1988169643   outside
      726  W2896826974 W2020118844   outside
      727  W2896826974 W2024493527   outside
      728  W2896826974 W2026164865   outside
      729  W2896826974 W2029391677   outside
      730  W2896826974 W2038196424   outside
      731  W2896826974 W2048438282   outside
      732  W2896826974 W2063103323   outside
      733  W2896826974 W2064816492   outside
      734  W2896826974 W2067517664   outside
      735  W2896826974 W2074002348   outside
      736  W2896826974 W2096360326   outside
      737  W2896826974 W2117449104   outside
      738  W2896826974 W2138893419   outside
      739  W2896826974 W2139073212   outside
      740  W2896826974 W2139282251   outside
      741  W2896826974 W2139466197   outside
      742  W2896826974 W2142756309   outside
      743  W2896826974 W2142877669   outside
      744  W2896826974 W2150290224   outside
      745  W2896826974 W2151071722   outside
      746  W2896826974 W2163887529   outside
      747  W2896826974 W2166317738   outside
      748  W2896826974 W2171124651   outside
      749  W2896826974 W2173130871   outside
      750  W2896826974 W2187587692   outside
      751  W2896826974 W2221554129   outside
      752  W2896826974 W2264501383   outside
      753  W2896826974 W2298224214   outside
      754  W2896826974 W2317269115   outside
      755  W2896826974 W2341508074   outside
      756  W2896826974 W2397349251   outside
      757  W2896826974 W2409787008   outside
      758  W2896826974 W2419419954   outside
      759  W2896826974 W2426372034   outside
      760  W2896826974 W2480924963   outside
      761  W2896826974 W2488987723   outside
      762  W2896826974 W2512078133   outside
      763  W2896826974 W2515889430   outside
      764  W2896826974 W2518646621   outside
      765  W2896826974 W2528406562   outside
      766  W2896826974 W2528525856   outside
      767  W2896826974 W2533200693   outside
      768  W2896826974 W2547617692   outside
      769  W2896826974 W2567946352   outside
      770  W2896826974 W2574963600   outside
      771  W2896826974 W2582736804   outside
      772  W2896826974 W2585624576   outside
      773  W2896826974 W2590116898   outside
      774  W2896826974 W2724499206   outside
      775  W2896826974 W2745888331   outside
      776  W2896826974 W2753968569   outside
      777  W2896826974 W2761768825   outside
      778  W2896826974 W2761849792   outside
      779  W2896826974 W2765323086   outside
      780  W2896826974 W2766079223   outside
      781  W2896826974 W2787214566   outside
      782  W2896826974 W2791998006   outside
      783  W2896826974 W2800179176   outside
      784  W2896826974 W2804683589   outside
      785  W2896826974 W2810937555   outside
      786  W2896826974 W2888849740   outside
      787  W2896826974 W2943554073   outside
      788  W2896826974 W2951488006   outside
      789  W2896826974 W2953318847   outside
      790  W2896826974 W2962678849   outside
      791  W2896826974 W2963409780   outside
      792  W2896826974 W2963761964   outside
      793  W2896826974 W3104705690   outside
      794  W2896826974 W3104812864   outside
      795  W2896826974 W3123158876   outside
      796  W2896826974 W3125777910   outside
      797  W2896826974 W3130540911   outside
      798  W2896826974 W3132937684   outside
      799  W2896826974  W319315373   outside
      800  W2896826974 W4211111750   outside
      801  W2896826974 W4211168474   outside
      802  W2896826974 W4256461005   outside
      803  W2896826974 W4300286877   outside
      804  W2896826974 W6677438736   outside
      805  W2896826974 W6680160629   outside
      806  W2896826974 W6680482912   outside
      807  W2896826974 W6721356872   outside
      808  W2896826974 W6722464371   outside
      809  W2896826974 W6729326792   outside
      810  W2896826974 W6754082931   outside
      811  W2896826974 W6761841844   outside
      812  W2896826974 W6818512912   outside
      813  W2911997761 W1514535095   outside
      814  W2911997761 W1522301498   outside
      815  W2911997761 W1566018662   outside
      816  W2911997761 W1610356397   outside
      817  W2911997761 W1622676895   outside
      818  W2911997761 W1660390307   outside
      819  W2911997761 W1793121960   outside
      820  W2911997761 W1801721664   outside
      821  W2911997761 W1832693441   outside
      822  W2911997761 W1880262756   outside
      823  W2911997761 W1902237438   outside
      824  W2911997761 W1965667542   outside
      825  W2911997761 W1966443646   outside
      826  W2911997761 W1995672491   outside
      827  W2911997761 W1998257453   outside
      828  W2911997761 W2049434052   outside
      829  W2911997761 W2064675550   outside
      830  W2911997761 W2066636486   outside
      831  W2911997761 W2071080574   outside
      832  W2911997761 W2098824882   outside
      833  W2911997761 W2100495367   outside
      834  W2911997761 W2103333826   outside
      835  W2911997761 W2119788759   outside
      836  W2911997761 W2123402141   outside
      837  W2911997761 W2127589108   outside
      838  W2911997761 W2156124259   outside
      839  W2911997761 W2162495634   outside
      840  W2911997761 W2171590421   outside
      841  W2911997761 W2178628967   outside
      842  W2911997761 W2211192759   outside
      843  W2911997761 W2251427843   outside
      844  W2911997761 W2252215182   outside
      845  W2911997761 W2402144811   outside
      846  W2911997761 W2407776548   outside
      847  W2911997761 W2470673105   outside
      848  W2911997761 W2483327705   outside
      849  W2911997761 W2508865106   outside
      850  W2911997761 W2510530102   outside
      851  W2911997761 W2510940142   outside
      852  W2911997761 W2536015822   outside
      853  W2911997761 W2556553881   outside
      854  W2911997761 W2563010554   outside
      855  W2911997761 W2592249290   outside
      856  W2911997761 W2648699835   outside
      857  W2911997761 W2742940593   outside
      858  W2911997761 W2766337907   outside
      859  W2911997761 W2788259284   outside
      860  W2911997761 W2803119681   outside
      861  W2911997761 W2963053846   outside
      862  W2911997761 W2963403868   outside
      863  W2911997761 W2964308564   outside
      864  W2911997761 W3016724004   outside
      865  W2911997761 W3102335248   outside
      866  W2911997761  W398859631   outside
      867  W2911997761 W4231510805   outside
      868  W2911997761 W4247950230   outside
      869  W2911997761  W581956982   outside
      870  W2911997761 W6637101025   outside
      871  W2911997761 W6727233892   outside
      872  W2936368166  W113836369   outside
      873  W2936368166 W1500256440   outside
      874  W2936368166 W1527786550   outside
      875  W2936368166 W1583837637   outside
      876  W2936368166 W1632114991   outside
      877  W2936368166 W1793121960   outside
      878  W2936368166 W1810943226   outside
      879  W2936368166 W1902237438   outside
      880  W2936368166 W1943478593   outside
      881  W2936368166 W1986868156   outside
      882  W2936368166 W2007709031   outside
      883  W2936368166 W2064675550   outside
      884  W2936368166 W2095705004   outside
      885  W2936368166 W2107878631   outside
      886  W2936368166 W2150824314   outside
      887  W2936368166 W2157331557   outside
      888  W2936368166 W2254175738   outside
      889  W2936368166 W2265796482   outside
      890  W2936368166 W2293453011   outside
      891  W2936368166 W2293771131   outside
      892  W2936368166 W2409027918   outside
      893  W2936368166 W2474920236   outside
      894  W2936368166 W2507756961   outside
      895  W2936368166 W2530887700   outside
      896  W2936368166 W2534274346   outside
      897  W2936368166 W2535697732   outside
      898  W2936368166 W2563734883   outside
      899  W2936368166 W2574535369   outside
      900  W2936368166 W2576915720   outside
      901  W2936368166 W2596567068   outside
      902  W2936368166 W2597601064   outside
      903  W2936368166 W2599674900   outside
      904  W2936368166 W2602856279   outside
      905  W2936368166 W2606974598   outside
      906  W2936368166 W2607303097   outside
      907  W2936368166 W2611684114   outside
      908  W2936368166 W2612560781   outside
      909  W2936368166 W2626194254   outside
      910  W2936368166 W2766736793   outside
      911  W2936368166 W2769152880   outside
      912  W2936368166 W2792048062   outside
      913  W2936368166 W2792376130   outside
      914  W2936368166 W2897139265   outside
      915  W2936368166 W2902716364   outside
      916  W2936368166 W2914584698   outside
      917  W2936368166 W2949615363   outside
      918  W2936368166 W2949888546   outside
      919  W2936368166 W2950527759   outside
      920  W2936368166 W2951605425   outside
      921  W2936368166 W2952507584   outside
      922  W2936368166 W2962730419   outside
      923  W2936368166 W2962790689   outside
      924  W2936368166 W2962933129   outside
      925  W2936368166 W2962940432   outside
      926  W2936368166 W2962972512   outside
      927  W2936368166 W2963042606   outside
      928  W2936368166 W2963374479   outside
      929  W2936368166 W2963385935   outside
      930  W2936368166 W2963735467   outside
      931  W2936368166 W2963929190   outside
      932  W2936368166 W2963984224   outside
      933  W2936368166 W2964121744   outside
      934  W2936368166 W2964269252   outside
      935  W2936368166 W2964304579   outside
      936  W2936368166 W2964308564   outside
      937  W2936368166 W2979240068   outside
      938  W2936368166 W2990953521   outside
      939  W2936368166 W3037932933   outside
      940  W2936368166 W3183988614   outside
      941  W2936368166 W3207342693   outside
      942  W2936368166 W4206584443   outside
      943  W2936368166 W4229748564   outside
      944  W2936368166 W4236965008   outside
      945  W2936368166 W4243055393   outside
      946  W2936368166 W4300402905   outside
      947  W2936368166   W69640471   outside
      948  W2938946739  W150699991   outside
      949  W2938946739 W1991713242   outside
      950  W2938946739 W2024075610   outside
      951  W2938946739 W2150220236   outside
      952  W2938946739 W2187569332   outside
      953  W2938946739 W2302501749   outside
      954  W2938946739 W2522413525   outside
      955  W2938946739 W2604156647   outside
      956  W2938946739 W2604994368   outside
      957  W2938946739 W2612009452   outside
      958  W2938946739 W2764161090   outside
      959  W2938946739 W2766227634   outside
      960  W2938946739 W2767865716   outside
      961  W2938946739 W2773787581   outside
      962  W2938946739 W2778697372   outside
      963  W2938946739 W2891148407   outside
      964  W2938946739 W2918895389   outside
      965  W2938946739 W2926606343   outside
      966  W2938946739 W3013305275   outside
      967  W2938946739 W3014060694   outside
      968  W2938946739 W3027132030   outside
      969  W2938946739  W403298716   outside
      970  W2938946739 W4386262759   outside
      971  W2938946739 W4394356984   outside
      972  W2938946739  W633162274   outside
      973  W2938946739 W6902274327   outside
      974  W2938946739 W6940036629   outside
      975  W2963341956  W131533222   outside
      976  W2963341956 W1486649854   outside
      977  W2963341956 W1566289585   outside
      978  W2963341956 W1599016936   outside
      979  W2963341956 W1840435438   outside
      980  W2963341956 W2025768430   outside
      981  W2963341956 W2108598243   outside
      982  W2963341956 W2117130368   outside
      983  W2963341956 W2121227244   outside
      984  W2963341956 W2130903752   outside
      985  W2963341956 W2131462252   outside
      986  W2963341956 W2131744502   outside
      987  W2963341956 W2144578941   outside
      988  W2963341956 W2149933564   outside
      989  W2963341956 W2158108973   outside
      990  W2963341956 W2158139315   outside
      991  W2963341956 W2170973209   outside
      992  W2963341956 W2251939518   outside
      993  W2963341956 W2270070752   outside
      994  W2963341956 W2396767181   outside
      995  W2963341956 W2413794162   outside
      996  W2963341956 W2462831000   outside
      997  W2963341956 W2507974895   outside
      998  W2963341956 W2551396370   outside
      999  W2963341956 W2610858497   outside
      1000 W2963341956 W2784823820   outside
      1001 W2963341956 W2880875857   outside
      1002 W2963341956 W2888329843   outside
      1003 W2963341956 W2891602716   outside
      1004 W2963341956 W2897076808   outside
      1005 W2963341956 W2951714314   outside
      1006 W2963341956 W2962718483   outside
      1007 W2963341956 W2962739339   outside
      1008 W2963341956 W2962808855   outside
      1009 W2963341956 W2963026768   outside
      1010 W2963341956 W2963088785   outside
      1011 W2963341956 W2963159690   outside
      1012 W2963341956 W2963339397   outside
      1013 W2963341956 W2963403868   outside
      1014 W2963341956 W2963563735   outside
      1015 W2963341956 W2963564796   outside
      1016 W2963341956 W2963644595   outside
      1017 W2963341956 W2963748441   outside
      1018 W2963341956 W2963756346   outside
      1019 W2963341956 W2963804993   outside
      1020 W2963341956 W2963846996   outside
      1021 W2963341956 W2963918774   outside
      1022 W2963341956 W2978670439   outside
      1023 W2963341956 W3098057198   outside
      1024 W2963341956 W3104033643   outside
      1025 W2965202507 W2403584057   outside
      1026 W2965202507 W2410402467   outside
      1027 W2965202507 W2764161090   outside
      1028 W2965202507 W2918895389   outside
      1029 W2965202507 W2981120761   outside
      1030 W2965202507 W3106477845   outside
      1031 W3045921891 W2962739339   outside
      1032 W3045921891 W2963090765   outside
      1033 W3045921891 W3101913037   outside
      1034 W3046863325 W3098501485   outside
      1035 W4293919086 W1993248021   outside
      1036 W4293919086 W2167632452   outside
      1037 W4293919086 W2751675383   outside
      1038 W4293919086 W2778795786   outside
      1039 W4293919086 W3033736142   outside
      1040 W4293919086 W3120758321   outside
      1041 W4293919086 W3122922982   outside
      1042 W4293919086 W3136369402   outside
      1043 W4293919086 W3147746548   outside
      1044 W4293919086 W3149838060   outside
      1045 W4293919086 W3158741648   outside
      1046 W4293919086 W3161803063   outside
      1047 W4293919086 W3174665049   outside
      1048 W4293919086 W3191542556   outside
      1049 W4293919086 W3191795768   outside
      1050 W4293919086 W3198568883   outside
      1051 W4293919086 W3204699421   outside
      1052 W4293919086 W3205277887   outside
      1053 W4293919086 W3207384088   outside
      1054 W4293919086 W3210898815   outside
      1055 W4293919086 W3216112305   outside
      1056 W4293919086 W3216439547   outside
      1057 W4293919086 W4200063888   outside
      1058 W4293919086 W4200114414   outside
      1059 W4293919086 W4205561404   outside
      1060 W4293919086 W4206717770   outside
      1061 W4293919086 W4207081009   outside
      1062 W4293919086 W4210517230   outside
      1063 W4293919086 W4213208566   outside
      1064 W4293919086 W4214903816   outside
      1065 W4293919086 W4220909391   outside
      1066 W4293919086 W4221021402   outside
      1067 W4293919086 W4283070526   outside
      1068 W4293919086 W4297670668   outside
      1069 W4311043552 W1739787994   outside
      1070 W4311043552 W2007872832   outside
      1071 W4311043552 W2033815440   outside
      1072 W4311043552 W2042084307   outside
      1073 W4311043552 W2089922390   outside
      1074 W4311043552 W2288823482   outside
      1075 W4311043552 W2785915606   outside
      1076 W4311043552 W2788730394   outside
      1077 W4311043552 W2804346410   outside
      1078 W4311043552 W2884069803   outside
      1079 W4311043552 W2887294148   outside
      1080 W4311043552 W2969805759   outside
      1081 W4311043552 W2969920179   outside
      1082 W4311043552 W3005831412   outside
      1083 W4311043552 W3013886637   outside
      1084 W4311043552 W3032952443   outside
      1085 W4311043552 W3034083433   outside
      1086 W4311043552 W3041998196   outside
      1087 W4311043552 W3111509751   outside
      1088 W4311043552 W3111616766   outside
      1089 W4311043552 W3112065274   outside
      1090 W4311043552 W3136182959   outside
      1091 W4311043552 W3147746548   outside
      1092 W4311043552 W3154161668   outside
      1093 W4311043552 W3158741648   outside
      1094 W4311043552 W3175946790   outside
      1095 W4311043552 W3191795768   outside
      1096 W4311043552 W3194028525   outside
      1097 W4311043552 W3200579686   outside
      1098 W4311043552 W3204517092   outside
      1099 W4311043552 W3205277887   outside
      1100 W4311043552 W3207384088   outside
      1101 W4311043552 W3208205279   outside
      1102 W4311043552 W3208886700   outside
      1103 W4311043552 W3210534219   outside
      1104 W4311043552 W3210898815   outside
      1105 W4311043552 W3215713008   outside
      1106 W4311043552 W3216112305   outside
      1107 W4311043552 W3216439547   outside
      1108 W4311043552 W4200063888   outside
      1109 W4311043552 W4200114414   outside
      1110 W4311043552 W4205832149   outside
      1111 W4311043552 W4206717770   outside
      1112 W4311043552 W4210517230   outside
      1113 W4311043552 W4210694094   outside
      1114 W4311043552 W4210739828   outside
      1115 W4311043552 W4213208566   outside
      1116 W4311043552 W4213426336   outside
      1117 W4311043552 W4220780942   outside
      1118 W4311043552 W4220909391   outside
      1119 W4311043552 W4221034259   outside
      1120 W4311043552 W4226032329   outside
      1121 W4311043552 W4285612256   outside
      1122 W4311043552 W4285613196   outside
      1123 W4311043552 W4295123433   outside
      1124 W4311043552 W4297198672   outside
      1125 W4311043552  W630157969   outside
      1126 W4387316167 W1968927634   outside
      1127 W4387316167 W1969442546   outside
      1128 W4387316167 W1988686126   outside
      1129 W4387316167 W2008883775   outside
      1130 W4387316167 W2018319765   outside
      1131 W4387316167 W2018695324   outside
      1132 W4387316167 W2018850751   outside
      1133 W4387316167 W2026032877   outside
      1134 W4387316167 W2031531534   outside
      1135 W4387316167 W2031565327   outside
      1136 W4387316167 W2059789020   outside
      1137 W4387316167 W2066766178   outside
      1138 W4387316167 W2069870183   outside
      1139 W4387316167 W2075140181   outside
      1140 W4387316167 W2076450330   outside
      1141 W4387316167 W2078396654   outside
      1142 W4387316167 W2080561126   outside
      1143 W4387316167 W2108883379   outside
      1144 W4387316167 W2109244020   outside
      1145 W4387316167 W2124949857   outside
      1146 W4387316167 W2148972377   outside
      1147 W4387316167 W2171622749   outside
      1148 W4387316167 W2416288882   outside
      1149 W4387316167 W2604418969   outside
      1150 W4387316167 W2615236232   outside
      1151 W4387316167 W2797019897   outside
      1152 W4387316167 W2806865696   outside
      1153 W4387316167 W2886307757   outside
      1154 W4387316167 W2886693919   outside
      1155 W4387316167 W2887157521   outside
      1156 W4387316167 W2946979871   outside
      1157 W4387316167 W2947689917   outside
      1158 W4387316167 W2947920450   outside
      1159 W4387316167 W2953926227   outside
      1160 W4387316167 W2967722518   outside
      1161 W4387316167 W2968473406   outside
      1162 W4387316167 W3013322209   outside
      1163 W4387316167 W3013638393   outside
      1164 W4387316167 W3013793288   outside
      1165 W4387316167 W3015713034   outside
      1166 W4387316167 W3033691903   outside
      1167 W4387316167 W3098543566   outside
      1168 W4387316167 W3098880357   outside
      1169 W4387316167 W3160543801   outside
      1170 W4387316167 W4200619326   outside
      1171 W4387316167 W4213009331   outside
      1172 W4387316167 W4225253269   outside
      1173 W4387316167 W4225575967   outside
      1174 W4387316167 W4229027214   outside
      1175 W4387316167 W4230856239   outside
      1176 W4387316167 W4242069725   outside
      1177 W4387316167 W4245785204   outside
      1178 W4387316167 W4245885733   outside
      1179 W4387316167 W4281653448   outside
      1180 W4387316167 W4306317389   outside
      1181 W4387316167   W60686164   outside
      1182 W4387316167   W63485078   outside
      1183 W4387316167 W6695163252   outside
      1184 W4387316167 W6753704364   outside
      1185 W4387316167 W6753892773   outside
      1186 W4387316167 W6754297074   outside
      1187 W4387316167 W6754379268   outside
      1188 W4387316167 W6762784677   outside
      1189 W4387316167 W6762883310   outside
      1190 W4387316167 W6775751263   outside
      1191 W4387316167 W6810635495   outside
      1192 W4387316167 W6838553971   outside
      1193 W4387316167 W6891825003   outside
      1194 W4415603090 W1971087125   outside
      1195 W4415603090 W2027663019   outside
      1196 W4415603090 W2048185449   outside
      1197 W4415603090 W2073023209   outside
      1198 W4415603090 W2097509366   outside
      1199 W4415603090 W2322381034   outside
      1200 W4415603090 W2518646621   outside
      1201 W4415603090 W2783957468   outside
      1202 W4415603090 W2904209657   outside
      1203 W4415603090 W2904769620   outside
      1204 W4415603090 W2917492883   outside
      1205 W4415603090 W2922853138   outside
      1206 W4415603090 W2952187784   outside
      1207 W4415603090 W2955748094   outside
      1208 W4415603090 W2989484692   outside
      1209 W4415603090 W2997371893   outside
      1210 W4415603090 W3048623625   outside
      1211 W4415603090 W3048827342   outside
      1212 W4415603090 W3102584386   outside
      1213 W4415603090 W3109228826   outside
      1214 W4415603090 W3122397942   outside
      1215 W4415603090 W3145209320   outside
      1216 W4415603090 W3169567877   outside
      1217 W4415603090 W3194803548   outside
      1218 W4415603090 W3200171648   outside
      1219 W4415603090 W3207963767   outside
      1220 W4415603090 W4210740051   outside
      1221 W4415603090 W4211084351   outside
      1222 W4415603090 W4233468685   outside
      1223 W4415603090 W4309452914   outside
      1224 W4415603090 W4313544910   outside
      1225 W4415603090 W4322492139   outside
      1226 W4415603090 W4379805495   outside
      1227 W4415603090 W4389144963   outside
      1228 W4415603090 W4389396016   outside
      1229 W4415603090 W4390344737   outside
      1230 W4415603090 W4390674594   outside
      1231 W4415603090 W4390755087   outside
      1232 W4415603090 W4394789349   outside
      1233 W4415603090 W4401669587   outside
      1234 W4416113766 W1487640135   outside
      1235 W4416113766 W1546171873   outside
      1236 W4416113766 W1560783210   outside
      1237 W4416113766 W1931854307   outside
      1238 W4416113766 W1968638613   outside
      1239 W4416113766 W1971871165   outside
      1240 W4416113766 W1979233281   outside
      1241 W4416113766 W1996299733   outside
      1242 W4416113766 W2000074009   outside
      1243 W4416113766 W2003844967   outside
      1244 W4416113766 W2014755794   outside
      1245 W4416113766 W2014782383   outside
      1246 W4416113766 W2016860460   outside
      1247 W4416113766 W2035735073   outside
      1248 W4416113766 W2054689332   outside
      1249 W4416113766 W2060348061   outside
      1250 W4416113766 W2071610639   outside
      1251 W4416113766 W2082044341   outside
      1252 W4416113766 W2086496065   outside
      1253 W4416113766 W2089123513   outside
      1254 W4416113766 W2089604928   outside
      1255 W4416113766 W2092079751   outside
      1256 W4416113766 W2094656162   outside
      1257 W4416113766 W2097111711   outside
      1258 W4416113766 W2097337742   outside
      1259 W4416113766 W2099424129   outside
      1260 W4416113766 W2100117397   outside
      1261 W4416113766 W2104772551   outside
      1262 W4416113766 W2106488040   outside
      1263 W4416113766 W2109170824   outside
      1264 W4416113766 W2115339903   outside
      1265 W4416113766 W2122831750   outside
      1266 W4416113766 W2123485782   outside
      1267 W4416113766 W2126326820   outside
      1268 W4416113766 W2148018888   outside
      1269 W4416113766 W2162430746   outside
      1270 W4416113766 W2170043925   outside
      1271 W4416113766 W2252474518   outside
      1272 W4416113766 W2304182900   outside
      1273 W4416113766 W2322381034   outside
      1274 W4416113766 W2520991028   outside
      1275 W4416113766 W2615601482   outside
      1276 W4416113766 W2660852010   outside
      1277 W4416113766 W2724497731   outside
      1278 W4416113766 W2759214027   outside
      1279 W4416113766 W2773610376   outside
      1280 W4416113766 W2786071730   outside
      1281 W4416113766 W2800757093   outside
      1282 W4416113766 W2884460088   outside
      1283 W4416113766 W2888665016   outside
      1284 W4416113766 W2892102552   outside
      1285 W4416113766 W2913613915   outside
      1286 W4416113766 W2917461057   outside
      1287 W4416113766 W2954205856   outside
      1288 W4416113766 W2963025906   outside
      1289 W4416113766 W2971499665   outside
      1290 W4416113766 W2980172586   outside
      1291 W4416113766 W3010205537   outside
      1292 W4416113766 W3021983181   outside
      1293 W4416113766 W3048623625   outside
      1294 W4416113766 W3116549010   outside
      1295 W4416113766 W3130342212   outside
      1296 W4416113766 W3170315082   outside
      1297 W4416113766 W3178786088   outside
      1298 W4416113766 W3194696510   outside
      1299 W4416113766 W4200499539   outside
      1300 W4416113766 W4230129368   outside
      1301 W4416113766 W4245964077   outside
      1302 W4416113766 W4254015553   outside
      1303 W4416113766 W4254502019   outside
      1304 W4416113766 W4283013804   outside
      1305 W4416113766 W4288059149   outside
      1306 W4416113766 W4292560495   outside
      1307 W4416113766 W4307902807   outside
      1308 W4416113766 W4309986598   outside
      1309 W4416113766 W4318615065   outside
      1310 W4416113766 W4360616504   outside
      1311 W4416113766 W4361004424   outside
      1312 W4416113766 W4377042089   outside
      1313 W4416113766 W4386605581   outside
      1314 W4416113766 W4387694169   outside
      1315 W4416113766 W4388188435   outside
      1316 W4416113766 W4389396016   outside
      1317 W4416113766 W4389442532   outside
      1318 W4416113766 W4390664718   outside
      1319 W4416113766 W4391654191   outside
      1320 W4416113766 W4397012038   outside
      1321 W4416113766 W4400056758   outside
      1322 W4416113766 W4402453776   outside
      1323 W4416113766 W4405528476   outside
      1324 W4416113766 W4409466709   outside
      1325 W4416113766  W606560209   outside
      1326 W7128689807 W1731700882   outside
      1327 W7128689807 W1758588624   outside
      1328 W7128689807 W1808807089   outside
      1329 W7128689807 W1835828514   outside
      1330 W7128689807 W1856837095   outside
      1331 W7128689807 W1907286193   outside
      1332 W7128689807 W1910490633   outside
      1333 W7128689807 W1965964177   outside
      1334 W7128689807 W1966117675   outside
      1335 W7128689807 W1971087125   outside
      1336 W7128689807 W1971906923   outside
      1337 W7128689807 W1973396742   outside
      1338 W7128689807 W1973775671   outside
      1339 W7128689807 W1974707207   outside
      1340 W7128689807 W1977358491   outside
      1341 W7128689807 W1979116104   outside
      1342 W7128689807 W1980282589   outside
      1343 W7128689807 W1982218215   outside
      1344 W7128689807 W1983118493   outside
      1345 W7128689807 W1995378367   outside
      1346 W7128689807 W2001851279   outside
      1347 W7128689807 W2003107619   outside
      1348 W7128689807 W2009405785   outside
      1349 W7128689807 W2022428934   outside
      1350 W7128689807 W2027703626   outside
      1351 W7128689807 W2029365116   outside
      1352 W7128689807 W2035478319   outside
      1353 W7128689807 W2035687655   outside
      1354 W7128689807 W2036420699   outside
      1355 W7128689807 W2038196424   outside
      1356 W7128689807 W2048185449   outside
      1357 W7128689807 W2049076011   outside
      1358 W7128689807 W2050790732   outside
      1359 W7128689807 W2054581441   outside
      1360 W7128689807 W2054650225   outside
      1361 W7128689807 W2054988762   outside
      1362 W7128689807 W2058730894   outside
      1363 W7128689807 W2065562675   outside
      1364 W7128689807 W2066104200   outside
      1365 W7128689807 W2067517664   outside
      1366 W7128689807 W2068452509   outside
      1367 W7128689807 W2069656088   outside
      1368 W7128689807 W2073023209   outside
      1369 W7128689807 W2073728848   outside
      1370 W7128689807 W2076447418   outside
      1371 W7128689807 W2080630898   outside
      1372 W7128689807 W2080736704   outside
      1373 W7128689807 W2081305716   outside
      1374 W7128689807 W2086496065   outside
      1375 W7128689807 W2088624593   outside
      1376 W7128689807 W2089604928   outside
      1377 W7128689807 W2095030488   outside
      1378 W7128689807 W2095149397   outside
      1379 W7128689807 W2100117397   outside
      1380 W7128689807 W2114081246   outside
      1381 W7128689807 W2118215647   outside
      1382 W7128689807 W2118398128   outside
      1383 W7128689807 W2121493052   outside
      1384 W7128689807 W2128349488   outside
      1385 W7128689807 W2129788001   outside
      1386 W7128689807 W2132478289   outside
      1387 W7128689807 W2133297042   outside
      1388 W7128689807 W2138357823   outside
      1389 W7128689807 W2139081384   outside
      1390 W7128689807 W2140880926   outside
      1391 W7128689807 W2144668267   outside
      1392 W7128689807 W2150220236   outside
      1393 W7128689807 W2162247560   outside
      1394 W7128689807 W2163887529   outside
      1395 W7128689807 W2164277894   outside
      1396 W7128689807 W2168201538   outside
      1397 W7128689807 W2169420254   outside
      1398 W7128689807 W2171420994   outside
      1399 W7128689807 W2171789734   outside
      1400 W7128689807 W2173388148   outside
      1401 W7128689807 W2203814174   outside
      1402 W7128689807 W2230357810   outside
      1403 W7128689807 W2241400277   outside
      1404 W7128689807 W2285073301   outside
      1405 W7128689807 W2296487136   outside
      1406 W7128689807 W2298224214   outside
      1407 W7128689807 W2315894413   outside
      1408 W7128689807 W2322381034   outside
      1409 W7128689807 W2339181936   outside
      1410 W7128689807 W2402239094   outside
      1411 W7128689807 W2473748898   outside
      1412 W7128689807 W2481585315   outside
      1413 W7128689807 W2511661767   outside
      1414 W7128689807 W2518646621   outside
      1415 W7128689807 W2523833024   outside
      1416 W7128689807 W2533043833   outside
      1417 W7128689807 W2555778826   outside
      1418 W7128689807 W2556015443   outside
      1419 W7128689807 W2560495985   outside
      1420 W7128689807 W2564742193   outside
      1421 W7128689807 W2567946352   outside
      1422 W7128689807 W2575212451   outside
      1423 W7128689807 W2599784308   outside
      1424 W7128689807 W2605637335   outside
      1425 W7128689807 W2605781715   outside
      1426 W7128689807 W2613734879   outside
      1427 W7128689807 W2620364655   outside
      1428 W7128689807 W2736598742   outside
      1429 W7128689807 W2741737307   outside
      1430 W7128689807 W2745888331   outside
      1431 W7128689807 W2753968569   outside
      1432 W7128689807 W2759214027   outside
      1433 W7128689807 W2763633408   outside
      1434 W7128689807 W2767761795   outside
      1435 W7128689807 W2784044787   outside
      1436 W7128689807 W2791879265   outside
      1437 W7128689807 W2793175961   outside
      1438 W7128689807 W2801169748   outside
      1439 W7128689807 W2803693948   outside
      1440 W7128689807 W2804384251   outside
      1441 W7128689807 W2810617143   outside
      1442 W7128689807 W2884405031   outside
      1443 W7128689807 W2885064209   outside
      1444 W7128689807 W2886599162   outside
      1445 W7128689807 W2891261767   outside
      1446 W7128689807 W2900746350   outside
      1447 W7128689807 W2903389621   outside
      1448 W7128689807 W2913788248   outside
      1449 W7128689807 W2917178759   outside
      1450 W7128689807 W2938840688   outside
      1451 W7128689807 W2947778969   outside
      1452 W7128689807 W2949887861   outside
      1453 W7128689807 W2949965121   outside
      1454 W7128689807 W2950850257   outside
      1455 W7128689807 W2955151262   outside
      1456 W7128689807 W2963059373   outside
      1457 W7128689807 W2963475133   outside
      1458 W7128689807 W2972876354   outside
      1459 W7128689807 W2974848855   outside
      1460 W7128689807 W2977092473   outside
      1461 W7128689807 W2983943611   outside
      1462 W7128689807 W2992072841   outside
      1463 W7128689807 W3000895385   outside
      1464 W7128689807 W3001137683   outside
      1465 W7128689807 W3004537452   outside
      1466 W7128689807 W3008649179   outside
      1467 W7128689807 W3009101358   outside
      1468 W7128689807 W3014734202   outside
      1469 W7128689807 W3023725873   outside
      1470 W7128689807 W3023758415   outside
      1471 W7128689807 W3029613260   outside
      1472 W7128689807 W3033813546   outside
      1473 W7128689807 W3036582436   outside
      1474 W7128689807 W3037203970   outside
      1475 W7128689807 W3037442288   outside
      1476 W7128689807 W3104705690   outside
      1477 W7128689807 W3111379976   outside
      1478 W7128689807 W3120962424   outside
      1479 W7128689807 W3123554164   outside
      1480 W7128689807 W3129570513   outside
      1481 W7128689807 W3131666551   outside
      1482 W7128689807 W3133727562   outside
      1483 W7128689807 W3136084339   outside
      1484 W7128689807 W3150373829   outside
      1485 W7128689807 W3151719968   outside
      1486 W7128689807 W3156399049   outside
      1487 W7128689807 W3161046293   outside
      1488 W7128689807 W3173521904   outside
      1489 W7128689807 W3174605565   outside
      1490 W7128689807 W3188229697   outside
      1491 W7128689807 W3192988845   outside
      1492 W7128689807 W3208960464   outside
      1493 W7128689807 W4205235314   outside
      1494 W7128689807 W4205332195   outside
      1495 W7128689807 W4205570389   outside
      1496 W7128689807 W4210732016   outside
      1497 W7128689807 W4210977614   outside
      1498 W7128689807 W4212863846   outside
      1499 W7128689807 W4214871668   outside
      1500 W7128689807 W4221006456   outside
      1501 W7128689807 W4221011625   outside
      1502 W7128689807 W4224223830   outside
      1503 W7128689807 W4224283948   outside
      1504 W7128689807 W4224316587   outside
      1505 W7128689807 W4226283917   outside
      1506 W7128689807 W4229617755   outside
      1507 W7128689807 W4230445262   outside
      1508 W7128689807 W4232875366   outside
      1509 W7128689807 W4237741312   outside
      1510 W7128689807 W4238447105   outside
      1511 W7128689807 W4240459956   outside
      1512 W7128689807 W4241026792   outside
      1513 W7128689807 W4244632359   outside
      1514 W7128689807 W4244857153   outside
      1515 W7128689807 W4280554058   outside
      1516 W7128689807 W4281630983   outside
      1517 W7128689807 W4281703169   outside
      1518 W7128689807 W4281974067   outside
      1519 W7128689807 W4283156505   outside
      1520 W7128689807 W4284989206   outside
      1521 W7128689807 W4290779485   outside
      1522 W7128689807 W4293109359   outside
      1523 W7128689807 W4296833817   outside
      1524 W7128689807 W4299419711   outside
      1525 W7128689807 W4304145091   outside
      1526 W7128689807 W4304689151   outside
      1527 W7128689807 W4306790721   outside
      1528 W7128689807 W4309530548   outside
      1529 W7128689807 W4312098068   outside
      1530 W7128689807 W4313545395   outside
      1531 W7128689807 W4318027904   outside
      1532 W7128689807 W4318618930   outside
      1533 W7128689807 W4319438842   outside
      1534 W7128689807 W4322492139   outside
      1535 W7128689807 W4324148415   outside
      1536 W7128689807 W4365138371   outside
      1537 W7128689807 W4377087659   outside
      1538 W7128689807 W4379012112   outside
      1539 W7128689807 W4379380011   outside
      1540 W7128689807 W4379805495   outside
      1541 W7128689807 W4380263869   outside
      1542 W7128689807 W4385248847   outside
      1543 W7128689807 W4385650775   outside
      1544 W7128689807 W4386195137   outside
      1545 W7128689807 W4386501102   outside
      1546 W7128689807 W4386919252   outside
      1547 W7128689807 W4388150685   outside
      1548 W7128689807 W4388174267   outside
      1549 W7128689807 W4388465513   outside
      1550 W7128689807 W4389704146   outside
      1551 W7128689807 W4391383086   outside
      1552 W7128689807 W4391801290   outside
      1553 W7128689807 W4392965502   outside
      1554 W7128689807 W4394135973   outside
      1555 W7128689807 W4394789349   outside
      1556 W7128689807 W4396220616   outside
      1557 W7128689807 W4398173679   outside
      1558 W7128689807 W4399128251   outside
      1559 W7128689807 W4399527568   outside
      1560 W7128689807 W4399944163   outside
      1561 W7128689807 W4399962909   outside
      1562 W7128689807 W4400078301   outside
      1563 W7128689807 W4401231426   outside
      1564 W7128689807 W4401669587   outside
      1565 W7128689807 W4402300412   outside
      1566 W7128689807 W4402758206   outside
      1567 W7128689807 W4402899540   outside
      1568 W7128689807 W4404156535   outside
      1569 W7128689807 W4404994307   outside
      1570 W7128689807 W4405260780   outside
      1571 W7128689807 W4405500230   outside
      1572 W7128689807 W4406153449   outside
      1573 W7128689807 W4406195046   outside
      1574 W7128689807 W4406549067   outside
      1575 W7128689807 W4408436836   outside
      1576 W7128689807 W4409254577   outside
      1577 W7128689807 W4409497235   outside
      1578 W7128689807 W4410174848   outside
      1579 W7128689807 W4410383927   outside
      1580 W7128689807 W4412611377   outside
      1581 W7128689807 W6939668080   outside
      1582 W7128689807 W6958081113   outside
      1583 W7128689807 W6976987486   outside
      1584 W7128689807  W767067438   outside
      1585   W91322025 W1559838295   outside
      1586   W91322025 W1605860798   outside
      1587   W91322025  W186897643   outside
      1588   W91322025 W1996250712   outside
      1589   W91322025 W2002664886   outside
      1590   W91322025 W2028473264   outside
      1591   W91322025 W2093506210   outside
      1592   W91322025 W2101390659   outside
      1593   W91322025 W2154498027   outside
      1594   W91322025 W2166706824   outside
      1595   W91322025 W2168190036   outside
      1596   W91322025 W2320766222   outside
      1597   W91322025 W2321621029   outside
      1598   W91322025 W2951278869   outside
      1599   W91322025 W6607569756   outside
      1600   W91322025 W6636142397   outside
      1601   W91322025 W7000635770   outside
      1602   W91322025 W7021264618   outside
      

# pro_snowball nodes content (id / oa_input / relation)

    Code
      print(dplyr::collect(dplyr::arrange(dplyr::select(results_pro$nodes, id,
      oa_input, relation), oa_input, relation)), n = Inf)
    Output
      # A tibble: 46 x 3
         id          oa_input relation
         <chr>       <lgl>    <chr>   
       1 W1500530942 FALSE    cited   
       2 W1516819724 FALSE    cited   
       3 W1525595230 FALSE    cited   
       4 W1572136682 FALSE    cited   
       5 W1854214752 FALSE    cited   
       6 W1909800943 FALSE    cited   
       7 W1996515099 FALSE    cited   
       8 W205532704  FALSE    cited   
       9 W2091406001 FALSE    cited   
      10 W2096537696 FALSE    cited   
      11 W2153579005 FALSE    cited   
      12 W2166481425 FALSE    cited   
      13 W2250539671 FALSE    cited   
      14 W2251249502 FALSE    cited   
      15 W2251861449 FALSE    cited   
      16 W2251869843 FALSE    cited   
      17 W2252212014 FALSE    cited   
      18 W2442495973 FALSE    cited   
      19 W2462443510 FALSE    cited   
      20 W2525778437 FALSE    cited   
      21 W2577479404 FALSE    cited   
      22 W2593028313 FALSE    cited   
      23 W2741809807 FALSE    cited   
      24 W2766528118 FALSE    cited   
      25 W2807650837 FALSE    cited   
      26 W2810053269 FALSE    cited   
      27 W2849933844 FALSE    cited   
      28 W2891066092 FALSE    cited   
      29 W2896826974 FALSE    cited   
      30 W2911997761 FALSE    cited   
      31 W2936368166 FALSE    cited   
      32 W2938946739 FALSE    cited   
      33 W2963118869 FALSE    cited   
      34 W2963341956 FALSE    cited   
      35 W2965202507 FALSE    cited   
      36 W296960487  FALSE    cited   
      37 W618607536  FALSE    cited   
      38 W91322025   FALSE    cited   
      39 W4293919086 FALSE    citing  
      40 W4311043552 FALSE    citing  
      41 W4387316167 FALSE    citing  
      42 W4415603090 FALSE    citing  
      43 W4416113766 FALSE    citing  
      44 W7128689807 FALSE    citing  
      45 W3045921891 TRUE     keypaper
      46 W3046863325 TRUE     keypaper

# pro_snowball edges content

    Code
      print(dplyr::collect(dplyr::arrange(results_pro$edges, edge_type, from, to)),
      n = Inf)
    Output
      # A tibble: 45 x 3
         from        to          edge_type
         <chr>       <chr>       <chr>    
       1 W3045921891 W1500530942 core     
       2 W3045921891 W1516819724 core     
       3 W3045921891 W1525595230 core     
       4 W3045921891 W1572136682 core     
       5 W3045921891 W1854214752 core     
       6 W3045921891 W1909800943 core     
       7 W3045921891 W205532704  core     
       8 W3045921891 W2091406001 core     
       9 W3045921891 W2096537696 core     
      10 W3045921891 W2153579005 core     
      11 W3045921891 W2166481425 core     
      12 W3045921891 W2250539671 core     
      13 W3045921891 W2251249502 core     
      14 W3045921891 W2251861449 core     
      15 W3045921891 W2251869843 core     
      16 W3045921891 W2252212014 core     
      17 W3045921891 W2442495973 core     
      18 W3045921891 W2462443510 core     
      19 W3045921891 W2525778437 core     
      20 W3045921891 W2577479404 core     
      21 W3045921891 W2593028313 core     
      22 W3045921891 W2741809807 core     
      23 W3045921891 W2807650837 core     
      24 W3045921891 W2810053269 core     
      25 W3045921891 W2849933844 core     
      26 W3045921891 W2891066092 core     
      27 W3045921891 W2896826974 core     
      28 W3045921891 W2911997761 core     
      29 W3045921891 W2936368166 core     
      30 W3045921891 W2963118869 core     
      31 W3045921891 W2963341956 core     
      32 W3045921891 W296960487  core     
      33 W3045921891 W618607536  core     
      34 W3045921891 W91322025   core     
      35 W3046863325 W1996515099 core     
      36 W3046863325 W2741809807 core     
      37 W3046863325 W2766528118 core     
      38 W3046863325 W2938946739 core     
      39 W3046863325 W2965202507 core     
      40 W4293919086 W3046863325 core     
      41 W4311043552 W3046863325 core     
      42 W4387316167 W3046863325 core     
      43 W4415603090 W3046863325 core     
      44 W4416113766 W3046863325 core     
      45 W7128689807 W3046863325 core     

# pro_snowball nodes match openalexR reference (zero diff)

    Code
      print(nodes_diff, n = Inf)
    Output
      # A tibble: 0 x 2
      # i 2 variables: id <chr>, oa_input <lgl>

# pro_snowball edges match openalexR reference (zero diff)

    Code
      print(edges_diff, n = Inf)
    Output
      # A tibble: 0 x 3
      # i 3 variables: from <chr>, to <chr>, edge_type <chr>

