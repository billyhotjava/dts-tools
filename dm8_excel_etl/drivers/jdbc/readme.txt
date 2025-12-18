/***************************************
 * 达梦8 JDBC驱动版本说明
/***************************************
1. DmJdbcDriver6 	实现JDBC 4.0标准接口，已在JDK6上验证相关功能
2. DmJdbcDriver7 	实现JDBC 4.1标准接口，已在JDK7上验证相关功能
3. DmJdbcDriver8 	实现JDBC 4.2标准接口，已在JDK8，JDK11，JDK17上验证相关功能
4. DmJdbcDriver11 	部分实现JDBC 4.3标准接口，已在JDK11，JDK17，JDK21上验证相关功能



/***************************************
 * 达梦8 hibernate方言包对应版本说明
/***************************************
jar包在dialect目录下:
1. DmDialect-for-hibernate2.0.jar  	对应 Jdk1.4及以上, hibernate2.0 环境
2. DmDialect-for-hibernate2.1.jar  	对应 Jdk1.4及以上, hibernate2.1 -- 2.X 环境
3. DmDialect-for-hibernate3.0.jar  	对应 Jdk1.4及以上, hibernate3.0 环境
4. DmDialect-for-hibernate3.1.jar  	对应 Jdk1.4及以上, hibernate3.1 -- 3.5 环境
5. DmDialect-for-hibernate3.6.jar  	对应 Jdk1.5及以上, hibernate3.6 -- 3.X 环境
6. DmDialect-for-hibernate4.0.jar  	对应 Jdk1.6及以上, hibernate4.0 -- 4.X 环境
7. DmDialect-for-hibernate5.0.jar  	对应 Jdk1.7及以上, hibernate5.0 环境
8. DmDialect-for-hibernate5.1.jar  	对应 Jdk1.7及以上, hibernate5.1 环境
9. DmDialect-for-hibernate5.2.jar  	对应 Jdk1.8及以上, hibernate5.2 环境
10. DmDialect-for-hibernate5.3.jar  	对应 Jdk1.8及以上, hibernate5.3 环境
11. DmDialect-for-hibernate5.4.jar  	对应 Jdk1.8及以上, hibernate5.4 环境
12. DmDialect-for-hibernate5.5.jar  	对应 Jdk1.8及以上, hibernate5.5 环境
13. DmDialect-for-hibernate5.6.jar  	对应 Jdk1.8及以上, hibernate5.6 环境
14. DmDialect-for-hibernate6.0.jar  	对应 Jdk1.8及以上, hibernate6.0 环境
15. DmDialect-for-hibernate6.1.jar  	对应 Jdk1.8及以上, hibernate6.1 环境
16. DmDialect-for-hibernate6.2.jar  	对应 Jdk1.8及以上, hibernate6.2 环境
17. DmDialect-for-hibernate6.3.jar  	对应 Jdk11及以上, hibernate6.3 环境
18. DmDialect-for-hibernate6.4.jar  	对应 Jdk11及以上, hibernate6.4 环境
19. DmDialect-for-hibernate6.5.jar  	对应 Jdk11及以上, hibernate6.5 环境
20. DmDialect-for-hibernate6.6.jar  	对应 Jdk11及以上, hibernate6.6 环境

注1：以上的hibernate版本指的是hibernate ORM版本，注意区分hibernate search版本
注2：DmDialect-for-hibernate5.4及以上版本，同步提供地理方言包，需要搭配geoutil-1.1.0.jar（详情见下方“其他jar包说明”）使用


/***************************************
 * Hibernate.cfg.xml配置说明
/***************************************
1、驱动名称
<property name="connection.driver_class">dm.jdbc.driver.DmDriver</property>

2、方言包名称
<property name="dialect">org.hibernate.dialect.DmDialect</property>



/***************************************
 * 其他jar包说明
/***************************************
1. dmjooq-dialect-3.12.3.jar     	jooq方言包，对应 Jdk1.8及以上环境
2. dm8-oracle-jdbc16-wrapper.jar    oracle 到达梦的JDBC驱动桥接，应用中如果使用了非标准的oracle JDBC特有的对象，无需修改应用代码，可以桥接到达梦的JDBC连接达梦数据库，对应 Jdk1.6及以上环境
3. gt-dameng-2.8.jar                GeoServer 2.8环境方言包，对应 Jdk1.6及以上环境
4. gt-dameng-2.11.jar               GeoServer 2.11环境方言包，对应 Jdk1.6及以上环境
5. gt-dameng-2.15.jar               GeoServer 2.15环境方言包，对应 Jdk1.6及以上环境
6. gt-dameng-2.16.jar               GeoServer 2.16环境方言包，对应 Jdk1.8及以上环境
7. gt-dameng-2.17.jar             	GeoServer 2.17环境方言包，对应 Jdk1.8及以上环境
8. gt-dameng-2.18.jar             	GeoServer 2.18环境方言包，对应 Jdk1.8及以上环境
9. gt-dameng-2.19.jar             	GeoServer 2.19环境方言包，对应 Jdk1.8及以上环境
10. gt-dameng-2.20.jar              GeoServer 2.20环境方言包，对应 Jdk1.8及以上环境
11. gt-dameng-2.21.jar              GeoServer 2.21环境方言包，对应 Jdk1.8及以上环境
12. gt-dmgeo2-2.8.jar               GeoServer 2.8环境方言包，对应 Jdk1.7及以上环境，需搭配geoutil-1.0.0.jar使用
13. gt-dmgeo2-2.11.jar              GeoServer 2.11环境方言包，对应 Jdk1.8及以上环境，需搭配geoutil-1.0.0.jar使用
14. gt-dmgeo2-2.13.jar              GeoServer 2.13环境方言包，对应 Jdk1.8及以上环境，需搭配geoutil-1.0.0.jar使用
15. gt-dmgeo2-2.14.jar              GeoServer 2.14环境方言包，对应 Jdk1.8及以上环境，需搭配geoutil-1.0.0.jar使用
16. gt-dmgeo2-2.15.jar              GeoServer 2.15环境方言包，对应 Jdk1.8及以上环境，需搭配geoutil-1.0.0.jar使用
17. gt-dmgeo2-2.16.jar              GeoServer 2.16环境方言包，对应 Jdk1.8及以上环境，需搭配geoutil-1.0.0.jar使用
18. gt-dmgeo2-2.20.jar              GeoServer 2.20环境方言包，对应 Jdk1.8及以上环境，需搭配geoutil-1.0.0.jar使用
19. gt-dmgeo2-2.22.jar              GeoServer 2.22环境方言包，对应 Jdk1.8及以上环境，需搭配geoutil-1.1.0.jar使用
20. gt-dmgeo2-2.24.jar              GeoServer 2.24环境方言包，对应 Jdk11及以上环境，需搭配geoutil-1.1.0.jar使用
21. geoutil-1.0.0.jar                     DmGeo2空间数据转换工具包，对应 Jdk1.6及以上环境
20. geoutil-1.1.0.jar                     DmGeo2空间数据转换工具包，对应 Jdk1.6及以上环境
21. brave-instrumentation-dm-5.4.3.jar	zipkin 5.4.3环境方言包，对应Jdk1.8及以上环境 		
22. DmSpatial-for-mybatisplus-1.0.0.jar   mybatisplus空间类型转换器，对应 Jdk17环境，需搭配geoutil-1.1.0.jar使用



/***************************************
 * maven仓库下载
/***************************************
group id: com.dameng
maven依赖配置示例: 
<dependency>
    <groupId>com.dameng</groupId>
    <artifactId>DmJdbcDriver8</artifactId>
    <version>8.1.3.162</version>
</dependency>
