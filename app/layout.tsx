import type {Metadata} from 'next';import './globals.css';
export const metadata:Metadata={title:'PolyEats — Good food. Campus close.',description:'An independent student-built campus food ordering demo with transparent nutrition.'};
export default function Layout({children}:{children:React.ReactNode}){return <html lang="en"><body>{children}</body></html>}
