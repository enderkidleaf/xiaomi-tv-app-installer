package com.enderkidleaf.tvinstaller;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.*;
import java.security.spec.*;
import java.util.*;

/** Read an existing authorized host key; test the exact Android transport against a real TV. */
public class AndroidTvSmoke {
    public static void main(String[] args)throws Exception{
        AdbCore.Endpoint endpoint=AdbCore.Endpoint.parse(args[0]);
        String pem=new String(Files.readAllBytes(Paths.get(args[1])),StandardCharsets.US_ASCII);
        String body=pem.replace("-----BEGIN PRIVATE KEY-----","").replace("-----END PRIVATE KEY-----","").replaceAll("\\s","");
        PrivateKey privateKey=KeyFactory.getInstance("RSA").generatePrivate(new PKCS8EncodedKeySpec(Base64.getDecoder().decode(body)));
        AdbCore.Keys keys=AdbCore.Keys.fromPrivate(privateKey);
        String info=AdbCore.shell(endpoint,keys,"getprop ro.product.model; getprop ro.build.version.release; getprop ro.product.cpu.abilist",10000,System.out::println);
        System.out.println("DEVICE: "+info.replace('\n',' '));
        String remote="/data/local/tmp/tv-installer-smoke-"+UUID.randomUUID()+".txt",content="TV installer Android transport verified.";
        try{
            byte[] data=content.getBytes(StandardCharsets.UTF_8);
            try(AdbCore.Connection connection=new AdbCore.Connection(endpoint,keys,System.out::println)){connection.push(new ByteArrayInputStream(data),data.length,remote,(done,total)->{});}
            String result=AdbCore.shell(endpoint,keys,"cat "+remote,10000,System.out::println);
            if(!content.equals(result.trim()))throw new AssertionError("SYNC roundtrip did not match");
            System.out.println("PASS: real TV RSA authentication, shell, SYNC upload and readback");
        }finally{AdbCore.shell(endpoint,keys,"rm -f "+remote,10000,System.out::println);}
    }
}
