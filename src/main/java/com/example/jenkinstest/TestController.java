package com.example.jenkinstest;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TestController {


    @RequestMapping("hello")
    public String hello(){
        return "明天肯定会更好！";
    }
}
