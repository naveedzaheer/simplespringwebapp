package com.nzdemo.simpletodo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

@Controller	// This means that this class is a Controller
public class BaseController {
	@GetMapping(path="/")
	public @ResponseBody String sayHello() {
		// This returns a JSON or XML with the users
		return "<H1>Hello All</H1>";
	}
}
