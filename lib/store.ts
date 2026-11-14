import type {Meal} from './data';
export type Line={id:string;meal:Meal;qty:number;price:number;choices:string[];notes:string;customized:boolean};
export const statuses=['Order placed','Preparing','Ready for pickup','Completed'] as const;
export type Order={id:string;number:string;code:string;created:string;status:typeof statuses[number];restaurant:string;pickup:string;items:Line[];total:number};
export type State={balance:number;orders:Order[];cart:Line[];favorites:string[];transactions:{id:string;amount:number;created:string}[]};
export const fresh=():State=>({balance:15000,orders:[],cart:[],favorites:[],transactions:[]});
export const KEY='polyeats-demo-v1';
export function total(lines:Line[]){return lines.reduce((s,l)=>s+l.price*l.qty,0)}
export function placeOrder(s:State,pickup:string):{state:State;order:Order}{
 const amount=total(s.cart);if(!s.cart.length)throw Error('Your bag is empty.');if(amount>s.balance)throw Error('Not enough simulated Dining Dollars. Remove an item or reset the demo.');
 if(new Set(s.cart.map(l=>l.meal.restaurant)).size!==1)throw Error('Please order from one restaurant at a time.');
 const id=crypto.randomUUID(),created=new Date().toISOString(); const order:Order={id,number:id.slice(0,5).toUpperCase(),code:String(Math.floor(1000+Math.random()*9000)),created,status:'Order placed',restaurant:s.cart[0].meal.restaurant,pickup,items:structuredClone(s.cart),total:amount};
 return {order,state:{...s,balance:s.balance-amount,cart:[],orders:[order,...s.orders],transactions:[{id,amount:-amount,created},...s.transactions]}};
}
export async function transact(fn:(s:State)=>State){const run=()=>{const next=fn(read());localStorage.setItem(KEY,JSON.stringify(next));window.dispatchEvent(new Event('polyeats-update'));return next};if(navigator.locks)return navigator.locks.request(KEY,run);return run()}
export function read():State{try {const raw=localStorage.getItem(KEY);return raw?JSON.parse(raw):fresh()}catch{return fresh()}}
