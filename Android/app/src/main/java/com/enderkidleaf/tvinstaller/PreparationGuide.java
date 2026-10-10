package com.enderkidleaf.tvinstaller;

import android.app.AlertDialog;
import android.text.util.Linkify;
import android.view.View;
import android.widget.*;
import org.json.*;
import java.io.*;

final class PreparationGuide {
    static void show(MainActivity app) {
        try {
            ByteArrayOutputStream data=new ByteArrayOutputStream();
            try(InputStream input=app.getAssets().open("PreparationGuide.json")){byte[] buffer=new byte[4096];int n;while((n=input.read(buffer))!=-1)data.write(buffer,0,n);}
            JSONObject guide=new JSONObject(data.toString("UTF-8"));
            LinearLayout root=app.vertical();root.setPadding(app.dp(16),app.dp(8),app.dp(16),app.dp(8));
            root.addView(app.text(guide.getString("intro"),12,false));
            root.addView(app.text("目标设备",12,true));Spinner device=new Spinner(app);root.addView(device);
            device.setAdapter(new ArrayAdapter<>(app,android.R.layout.simple_spinner_dropdown_item,new String[]{"手机 / 平板","电视 / 机顶盒"}));
            root.addView(app.text("连接方式",12,true));Spinner mode=new Spinner(app);root.addView(mode);
            mode.setAdapter(new ArrayAdapter<>(app,android.R.layout.simple_spinner_dropdown_item,new String[]{"普通网络 ADB","无线调试配对","先用 USB 开启"}));
            ScrollView scroll=new ScrollView(app);LinearLayout steps=app.vertical();scroll.addView(steps);
            int height=(int)(app.getResources().getDisplayMetrics().heightPixels*0.46f);root.addView(scroll,new LinearLayout.LayoutParams(-1,height));
            Runnable render=()->{
                try{
                    String type=device.getSelectedItemPosition()==0?"phone":"tv",method=new String[]{"tcp","pair","usb"}[mode.getSelectedItemPosition()];
                    steps.removeAllViews();JSONArray sections=guide.getJSONArray("sections");int index=0;
                    for(int i=0;i<sections.length();i++){
                        JSONObject section=sections.getJSONObject(i);String d=section.getString("device"),m=section.getString("mode");
                        if((d.equals("all")||d.equals(type))&&(m.equals("all")||m.equals(method))){
                            app.space(steps,12);steps.addView(app.text((++index)+". "+section.getString("title"),15,true));
                            TextView body=app.text(section.getString("body"),13,false);body.setTextIsSelectable(true);steps.addView(body);
                        }
                    }
                    app.space(steps,14);steps.addView(app.text("官方参考 · 步骤随设备型号和系统变化",13,true));JSONArray sources=guide.getJSONArray("sources");
                    for(int i=0;i<sources.length();i++){JSONObject source=sources.getJSONObject(i);TextView link=app.text(source.getString("title")+"\n"+source.getString("url"),12,false);Linkify.addLinks(link,Linkify.WEB_URLS);steps.addView(link);}
                    scroll.post(()->scroll.scrollTo(0,0));
                }catch(JSONException e){steps.removeAllViews();steps.addView(app.text("教程内容读取失败，请重新安装完整 APK。",13,false));}
            };
            AdapterView.OnItemSelectedListener listener=new AdapterView.OnItemSelectedListener(){public void onItemSelected(AdapterView<?> p,View v,int position,long id){render.run();}public void onNothingSelected(AdapterView<?> p){}};
            device.setOnItemSelectedListener(listener);mode.setOnItemSelectedListener(listener);render.run();
            new AlertDialog.Builder(app).setTitle(guide.getString("title")).setView(root).setPositiveButton("关闭",null).show();
        }catch(Exception e){new AlertDialog.Builder(app).setTitle("连接前准备教程").setMessage("未找到内置教程，请重新安装完整 APK。").setPositiveButton("关闭",null).show();}
    }
}
