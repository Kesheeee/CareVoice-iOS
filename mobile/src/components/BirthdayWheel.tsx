import { useEffect, useRef } from "react";

export function BirthdayWheel({label, value, options, onChange}: {label:string; value:string; options:{value:string;label:string}[]; onChange:(value:string)=>void}) {
  const ref = useRef<HTMLDivElement>(null);
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const items = [{value:"",label:"—"}, ...options];
  const current = Math.max(0, items.findIndex(item=>item.value===value));
  useEffect(()=>{if(ref.current) ref.current.scrollTop=current*44;},[value]);
  useEffect(()=>()=>clearTimeout(timer.current),[]);
  const choose = (index:number) => {
    const next = Math.max(0,Math.min(items.length-1,index));
    onChange(items[next].value);
    ref.current?.scrollTo({top:next*44,behavior:"smooth"});
  };
  return <div className="birthday-wheel-column"><span className="birthday-wheel-label">{label}</span>
    <div ref={ref} className="birthday-wheel" role="listbox" aria-label={label} tabIndex={0}
      onKeyDown={e=>{if(["ArrowUp","ArrowDown","Home","End"].includes(e.key)){e.preventDefault();choose(e.key==="Home"?0:e.key==="End"?items.length-1:current+(e.key==="ArrowDown"?1:-1));}}}
      onScroll={()=>{clearTimeout(timer.current);timer.current=setTimeout(()=>{const index=Math.round((ref.current?.scrollTop??0)/44);if(items[index] && items[index].value!==value)onChange(items[index].value);},140);}}>
      {items.map((item,i)=><div role="option" aria-selected={item.value===value} key={item.value} className="birthday-wheel-option" onClick={()=>choose(i)}>{item.label}</div>)}
    </div></div>;
}
