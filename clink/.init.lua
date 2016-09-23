local dirname = debug.getinfo(1, "S").source:match[[^@?(.*[\/])[^\/]-$]]
package.path = dirname .."?.lua;".. package.path
package.path = dirname .."completions/modules/?.lua;".. package.path
